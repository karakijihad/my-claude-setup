# Sourced by hooks. Provides parse_all (tool_input command / file_path /
# notebook_path) and parse_stop (last_assistant_message / stop_hook_active),
# each reading the stdin JSON already in $INPUT. jq if present, else a Python
# located by py.sh. Empty strings on failure — every caller must fail open.
#
# Both probe jq by *running* it rather than asking whether the name resolves:
# a jq on PATH that fails to execute would otherwise take the branch, return
# nothing, and leave a hook reading every field as absent.
#
# Goes through py.sh rather than naming `python`/`python3`, for the reason py.sh
# documents: on Windows those names are usually 0-byte Store stubs that exist on
# PATH and exit 9009 without running. A `command -v` existence check finds one,
# this parser then returns "" for every field, and guard.sh reads that as a tool
# call with no command and no file_path — silently skipping every check it makes.

_LIB_PARSE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


# parse_all — sets CMD, FILE and NBPATH from one interpreter call.
#
# guard.sh once read its three fields one at a time, paying a separate jq spawn
# for each. Measured on Windows 2026-08-12: process spawns here run 90-200ms
# apiece, so those calls plus a separate jq-probe were ~370ms of guard.sh's
# ~930ms. This does the probe and the extraction in a single call: jq that is
# missing or a broken stub writes nothing, which lands in the same empty-output
# branch as a payload that genuinely had no fields, and Python gets its turn.
#
# NUL-delimited, and read straight from a process substitution rather than a
# command substitution, because a bash variable cannot hold a NUL byte — $(...)
# would silently eat the delimiters. Tabs and newlines survive intact, which
# @tsv would have escaped; a heredoc in tool_input.command is normal.
_PY_PARSE_ALL="
import json,sys
try:
    obj=json.loads(sys.stdin.buffer.read().decode('utf-8','replace') or '{}')
    ti=obj.get('tool_input')
    if not isinstance(ti,dict): ti={}
    vals=[ti.get('command',''),ti.get('file_path',''),ti.get('notebook_path','')]
except Exception:
    vals=['','','']
w=sys.stdout.buffer
for v in vals:
    w.write((v if isinstance(v,str) else '').encode('utf-8','replace')+b'\\x00')
"

_JQ_PARSE_ALL='(.tool_input.command // ""), "\u0000",
               (.tool_input.file_path // ""), "\u0000",
               (.tool_input.notebook_path // ""), "\u0000"'

parse_all() {
  CMD=""; FILE=""; NBPATH=""
  { IFS= read -r -d '' CMD; IFS= read -r -d '' FILE; IFS= read -r -d '' NBPATH; } \
    < <(printf '%s' "$INPUT" | jq -j "$_JQ_PARSE_ALL" 2>/dev/null)
  [ -n "$CMD$FILE$NBPATH" ] && return 0

  CMD=""; FILE=""; NBPATH=""
  { IFS= read -r -d '' CMD; IFS= read -r -d '' FILE; IFS= read -r -d '' NBPATH; } \
    < <(printf '%s' "$INPUT" | bash "$_LIB_PARSE_DIR/py.sh" -c "$_PY_PARSE_ALL" 2>/dev/null)
  return 0
}

# parse_stop — sets MSG and ACTIVE for the SubagentStop hook.
#
# A single-field helper could not do this pair. A JSON boolean stringifies
# differently on the two branches — jq yields "true" where a naive Python read
# yields "" for anything that is not a string — so the loop guard would have
# read as absent on exactly the machines this plugin exists for. One call,
# NUL-delimited, both branches stringifying the boolean the same way.
# Same process-substitution reasoning as parse_all: a bash variable cannot hold
# NUL.
_PY_PARSE_STOP="
import json,sys
try:
    obj=json.loads(sys.stdin.buffer.read().decode('utf-8','replace') or '{}')
    m=obj.get('last_assistant_message','')
    a=obj.get('stop_hook_active')
    vals=[m if isinstance(m,str) else '', 'true' if a is True else '', 'ok']
except Exception:
    vals=['','','']
w=sys.stdout.buffer
for v in vals:
    w.write(v.encode('utf-8','replace')+b'\\x00')
"

_JQ_PARSE_STOP='(.last_assistant_message // ""), "\u0000",
                (if .stop_hook_active == true then "true" else "" end), "\u0000",
                "ok", "\u0000"'

parse_stop() {
  local ran
  MSG=""; ACTIVE=""; ran=""
  { IFS= read -r -d '' MSG; IFS= read -r -d '' ACTIVE; IFS= read -r -d '' ran; } \
    < <(printf '%s' "$INPUT" | jq -j "$_JQ_PARSE_STOP" 2>/dev/null)
  # A sentinel, not `[ -n "$MSG$ACTIVE" ]` as parse_all does. Both of these
  # fields are legitimately empty on a common payload — a read-only agent that
  # stopped with no final text — so testing the values cannot tell "jq ran and
  # found nothing" from "jq is not here", and every such stop paid a second
  # interpreter spawn to learn nothing. This event fires once per agent, and the
  # read-only agents the fan-out rule encourages are exactly that payload.
  [ -n "$ran" ] && return 0

  MSG=""; ACTIVE=""
  { IFS= read -r -d '' MSG; IFS= read -r -d '' ACTIVE; } \
    < <(printf '%s' "$INPUT" | bash "$_LIB_PARSE_DIR/py.sh" -c "$_PY_PARSE_STOP" 2>/dev/null)
  return 0
}
