#!/bin/bash
# PostToolBatch. Never blocks: exit 2 is reserved for guard.sh's safety refusal,
# the only sanctioned use left, and this is not it — so every path here exits 0.
#
# The model cannot see its own token usage -- no hook payload carries it. A
# sibling piece (assets/statusline.mjs) writes the session's fill to a state
# file on every status-line render; this hook reads that file and, once per
# 5%-of-context crossing, tells the model where it stands. Past a budget it
# escalates to a handoff directive.
#
# PostToolBatch, not PostToolUse: PostToolUse fires per tool call and runs
# concurrently for a parallel batch, which would race the ratchet file below.
# PostToolBatch fires exactly once, after the whole batch resolves and before
# the next model call -- this plugin's install of Claude Code 2.1.273 confirms
# the event exists and carries session_id/agent_id like other hook payloads.
#
# Rejections ordered cheapest-first, same reasoning as post-push.sh: a stdin
# read and a couple of string compares before any file I/O, and no file I/O
# at all before the ratchet's own cheap integer compare.

# `read`, not `$(cat)` -- see post-push.sh's note; same cost, same fix.
IFS= read -r -d '' INPUT

# --- 1. Subagent check --------------------------------------------------
# lib-parse.sh's parse_all only extracts tool_input fields (command/file_path/
# notebook_path); session_id and agent_id live at the payload's top level, so
# they need their own extraction. Same jq-then-py.sh idiom lib-parse.sh uses:
# probe jq by running it, fall through to py.sh (never `python3` directly) if
# jq is absent, broken, or the payload is malformed -- either way both fields
# come back empty and step 2 below exits quietly.
#
# Newline-delimited rather than lib-parse.sh's NUL-delimited scheme: none of
# the fields this hook reads (session_id, agent_id, used, size, pct) can hold
# an embedded newline in a well-formed payload, so there is no need for a NUL
# separator here -- and on this plugin's own jq build a literal NUL in a jq
# program string is not passed through cleanly (it never reaches argv intact,
# since a NUL ends a C string), so avoiding it here is deliberate, not an
# oversight.
_JQ_TOP='(.session_id // ""), (.agent_id // "")'
_PY_TOP="
import json,sys
try:
    obj=json.loads(sys.stdin.buffer.read().decode('utf-8','replace') or '{}')
    sid=obj.get('session_id','')
    aid=obj.get('agent_id','')
    vals=[sid if isinstance(sid,str) else '', aid if isinstance(aid,str) else '']
except Exception:
    vals=['','']
for v in vals:
    sys.stdout.write(v.replace(chr(10),' ').replace(chr(13),' ') + chr(10))
"

# Cheapest first, and this is the cheapest there is: session_id and agent_id
# are flat string fields on the payload object, so bash reads them itself with
# no process at all. That matters because this hook fires on every tool batch
# and the overwhelming majority of those end in a silent exit at the ratchet
# below -- paying an interpreter spawn (90-200ms on Windows, per lib-parse.sh)
# to learn nothing is the cost this ordering exists to avoid.
#
# A regex alone cannot do it. It takes the first match in the raw payload, and
# a PostToolBatch payload carries the whole tool_calls array, so a tool whose
# *structured* input has a session_id or agent_id key of its own wins. That is
# not hypothetical: it silently disabled the hook, and a nested agent_id made
# the main session look like a subagent. Checking whether the guess found a
# state file is not enough either -- a nested id that collides with a real
# session still inside the prune window has one, and then the wrong session's
# fill gets reported as this one's.
#
# So the count decides, not the match. Counting is pure parameter expansion,
# still no process. Exactly one "session_id" key in the payload means the
# regex cannot have matched anything else, and zero "agent_id" keys means
# there is certainly no subagent. Anything else is ambiguous and goes to the
# interpreter, which knows what a top-level field is.
#
# (Text inside a string value is safe either way: JSON escapes it to
# \"session_id\", which neither the count nor the regex matches. Verified.)
_KS='"session_id"'; _KA='"agent_id"'
_T=${INPUT//"$_KS"/}; N_SID=$(( (${#INPUT} - ${#_T}) / ${#_KS} ))
_T=${INPUT//"$_KA"/}; N_AID=$(( (${#INPUT} - ${#_T}) / ${#_KA} ))

SESSION_ID=""; AGENT_ID=""
if [ "$N_SID" = 1 ] && [ "$N_AID" = 0 ]; then
  [[ $INPUT =~ \"session_id\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && SESSION_ID="${BASH_REMATCH[1]}"
else
  # `tr -d '\r'` on every branch: a native Windows jq.exe or python.exe opens
  # piped stdout in text mode and turns each "\n" into "\r\n", which a bash
  # `read -r` does not strip -- an empty field's line then reads back as a
  # lone "\r", which is non-empty and would misread as a present agent_id.
  { IFS= read -r SESSION_ID; IFS= read -r AGENT_ID; } \
    < <(printf '%s' "$INPUT" | jq -r "$_JQ_TOP" 2>/dev/null | tr -d '\r')
  if [ -z "$SESSION_ID$AGENT_ID" ]; then
    SESSION_ID=""; AGENT_ID=""
    { IFS= read -r SESSION_ID; IFS= read -r AGENT_ID; } \
      < <(printf '%s' "$INPUT" | bash "$(dirname "$0")/py.sh" -c "$_PY_TOP" 2>/dev/null | tr -d '\r')
  fi
fi

# A subagent's own fill is not the main session's fill, and it must not be
# nudged about it -- silently, no output at all.
[ -n "$AGENT_ID" ] && exit 0

# --- 2. Locate and validate the state file ------------------------------
[ -z "$SESSION_ID" ] && exit 0

# Sanitised the same way budget.sh keys its ratchet mark: session_id becomes a
# filename, so it is reduced to a safe charset rather than trusted as a path
# component.
SAFE_ID=${SESSION_ID//[^A-Za-z0-9._-]/_}
[ -z "$SAFE_ID" ] && exit 0

CACHE_REL=".claude/cache/my-claude-setup"

# USERPROFILE first, then HOME -- the same precedence the sensor uses, because
# the two must agree about which file they mean. The sensor is node spawned by
# the harness, where USERPROFILE is set and HOME often is not; this is bash,
# where HOME is always set. On a stock Git Bash both name the same directory in
# different notations. A pinned HOME, a redirected corporate profile, or a CI
# image that sets only one separates them -- and then a reader that guessed the
# other root looks where the writer never wrote, silently.
STATE_FILE=""
for _root in "${USERPROFILE:-}" "${HOME:-}"; do
  [ -z "$_root" ] && continue
  case "$_root" in
    *\*) _root=$(cygpath -u "$_root" 2>/dev/null) || continue ;;
  esac
  [ -z "$_root" ] && continue
  if [ -f "$_root/$CACHE_REL/$SAFE_ID.json" ]; then
    CACHE_DIR="$_root/$CACHE_REL"
    STATE_FILE="$CACHE_DIR/$SAFE_ID.json"
    break
  fi
done
[ -z "$STATE_FILE" ] && exit 0

_JQ_STATE='(.session_id // ""), (.used // ""), (.size // ""), (.pct // "")'
_PY_STATE="
import json,sys
try:
    obj=json.loads(sys.stdin.buffer.read().decode('utf-8','replace') or '{}')
    sid=obj.get('session_id','')
    def s(v):
        return v if isinstance(v,str) else ('' if v is None else str(v))
    vals=[s(sid), s(obj.get('used')), s(obj.get('size')), s(obj.get('pct'))]
except Exception:
    vals=['','','','']
for v in vals:
    sys.stdout.write(v.replace(chr(10),' ').replace(chr(13),' ') + chr(10))
"

ST_SID=""; USED=""; SIZE=""; PCT=""
{ IFS= read -r ST_SID; IFS= read -r USED; IFS= read -r SIZE; IFS= read -r PCT; } \
  < <(jq -r "$_JQ_STATE" < "$STATE_FILE" 2>/dev/null | tr -d '\r')
if [ -z "$ST_SID$USED$SIZE$PCT" ]; then
  ST_SID=""; USED=""; SIZE=""; PCT=""
  { IFS= read -r ST_SID; IFS= read -r USED; IFS= read -r SIZE; IFS= read -r PCT; } \
    < <(bash "$(dirname "$0")/py.sh" -c "$_PY_STATE" < "$STATE_FILE" 2>/dev/null | tr -d '\r')
fi

# Malformed content, a torn write that produced valid-but-empty JSON, or a
# state file left over from a different session (the state contract's own
# session_id disagreeing with the payload's) -- all the same outcome: quiet.
[ -z "$ST_SID" ] && exit 0
[ "$ST_SID" != "$SESSION_ID" ] && exit 0
case "$USED" in ''|*[!0-9]*) exit 0 ;; esac
case "$SIZE" in ''|*[!0-9]*) exit 0 ;; esac
case "$PCT"  in ''|*[!0-9]*) exit 0 ;; esac
[ "$SIZE" -le 0 ] && exit 0

# --- 3. Budget in tokens -------------------------------------------------
BUDGET=""
case "${CLAUDE_HANDOFF_BUDGET:-}" in
  ''|*[!0-9]*) ;;
  0) ;;
  *) BUDGET="$CLAUDE_HANDOFF_BUDGET" ;;
esac
[ -z "$BUDGET" ] && BUDGET=$((SIZE * 60 / 100))

# --- 4. Ratchet on the 5%-of-context bucket -------------------------------
BUCKET=$((PCT / 5))
BAND_FILE="$CACHE_DIR/$SAFE_ID.band"

# Trust the cache dir or don't use it -- same reasoning as budget.sh's
# STATE_OK guard: a predictable path on a shared, writable location could be
# pre-planted as a symlink. The directory already exists (the sibling script
# writes the state file into it), so this is a defensive mkdir, not the first
# creation.
mkdir -p "$CACHE_DIR" 2>/dev/null
CACHE_OK=1
{ [ -d "$CACHE_DIR" ] && [ ! -L "$CACHE_DIR" ] && [ -O "$CACHE_DIR" ]; } || CACHE_OK=0

LAST=-1
if [ "$CACHE_OK" = 1 ] && [ -f "$BAND_FILE" ] && [ ! -L "$BAND_FILE" ]; then
  read -r LAST < "$BAND_FILE" 2>/dev/null
  case "$LAST" in ''|*[!0-9]*) LAST=-1 ;; esac
fi

[ "$BUCKET" -le "$LAST" ] && exit 0

if [ "$CACHE_OK" = 1 ]; then
  [ -L "$BAND_FILE" ] && rm -f -- "$BAND_FILE" 2>/dev/null
  printf '%s' "$BUCKET" > "$BAND_FILE" 2>/dev/null
fi

# --- 5. Format and emit ---------------------------------------------------
# Rounded to the nearest k, size to the nearest tenth of an M -- floating-point
# formatting bash's own integer arithmetic doesn't do, hence awk rather than
# another interpreter spawn through py.sh for three divisions.
read -r KU KB SM KS < <(awk -v u="$USED" -v b="$BUDGET" -v s="$SIZE" \
  'BEGIN { printf "%d %d %.1f %d\n", (u/1000)+0.5, (b/1000)+0.5, s/1000000, (s/1000)+0.5 }' | tr -d '\r')

# A 200k window reads as "0.2M", which is worse than "200k". Tenths of an M
# only once there is a whole M to take a tenth of.
if [ "$SIZE" -ge 1000000 ]; then WIN="${SM}M"; else WIN="${KS}k"; fi

if [ "$USED" -ge "$BUDGET" ]; then
  MSG="[context] ${KU}k/${WIN} (${PCT}%) — past the ${KB}k handoff budget. Write the handoff per my-claude-setup:project-docs now, and in your next reply give the operator its path and tell them to start a fresh session; you cannot start one yourself. If this budget is wrong, it is the CLAUDE_HANDOFF_BUDGET environment variable."
else
  MSG="[context] ${KU}k/${WIN} (${PCT}%) · handoff budget ${KB}k"
fi

# hookSpecificOutput WITH hookEventName -- a bare additionalContext is the
# SDK/Copilot shape and Claude Code discards it silently. Every value folded
# into MSG above is either digits or a fixed literal, so nothing here needs
# JSON escaping.
printf '{"hookSpecificOutput":{"hookEventName":"PostToolBatch","additionalContext":"%s"}}\n' "$MSG"

exit 0
