#!/bin/bash
# PostToolUse (Write|Edit — keep hooks.json's matcher in sync). Never blocks.
#
# Warns when a project doc outgrows the budget in its template header. PostToolUse
# rather than guard.sh because an Edit payload carries only two strings, so the
# resulting line count is knowable only after the write.
#
# THE RATCHET IS THE DESIGN: warn on the first crossing, again only when an edit
# makes the overage worse, silent on edits that hold or shrink. A hook that
# re-warns on the corrective edit is one the session learns to ignore.

# `read`, not `$(cat)` — cat is an external binary, and this runs on every write.
IFS= read -r -d '' INPUT

# Cheapest rejection first: no "docs" anywhere in the payload, nothing to do.
shopt -s nocasematch
[[ $INPUT == *docs* ]] || { shopt -u nocasematch; exit 0; }
shopt -u nocasematch

. "$(dirname "$0")/lib-parse.sh"
parse_all
[ -z "$FILE" ] && exit 0

FILE_N=${FILE//\\//}   # Windows payloads are backslash-delimited; guard.sh does the same.

# Both spellings: file_path is normally absolute, but a relative one has no
# leading separator and would otherwise be waved through.
case "$FILE_N" in
  */[Dd]ocs/*|[Dd]ocs/*) ;;
  *) exit 0 ;;
esac

BASE=${FILE_N##*/}

# Keyed on names, which is why planning-protocol §3 makes them normative — a hook
# cannot tell an index from a phase by reading it. Numbers are a second copy of
# the template headers; a suite assertion pins them together. GOVERNANCE.md and
# SESSION-RITUAL.md have no template: they are budgeted only because they are
# where banned content lands once the index stops accepting it.
#
# REMEDY is the half that matters. "Over budget" alone tells a session to compress
# prose, which is the wrong repair for every file here.
shopt -s nocasematch
case "$BASE" in
  INDEX.md)
    BUDGET=100
    REMEDY="An index tracks; it does not narrate. What landed is in git log, binding rulings go to Docs/Decisions/ — a 'Session history' or 'What landed' section does not belong here at all." ;;
  GOVERNANCE.md)
    BUDGET=60
    REMEDY="Governance holds stable rules, not state. Anything that changes as work proceeds belongs in INDEX.md's phase table." ;;
  SESSION-RITUAL.md)
    BUDGET=40
    REMEDY="A ritual is a procedure — open, check, close. If it has grown it is carrying state that belongs in INDEX.md." ;;
  phase-*.md)
    BUDGET=200
    REMEDY="A phase over budget is a phase too large, not prose too loose. Split it, where each half has its own exit criterion, and delete superseded scope rather than keeping it struck through." ;;
  CODEMAP.md|CODE-MAP.md)
    BUDGET=300
    REMEDY="Roles, not histories. How it got that way is in the commits; mechanism is in the source." ;;
  Backlog.md|Deferred.md)
    BUDGET=200
    REMEDY="Open items only, five lines each. Landed entries are deleted in the pass that closes them." ;;
  *)
    # A bare .md in Plan/ is a single-file plan, which §3 still allows for small work.
    case "$FILE_N" in
      */[Pp]lan/*.md) BUDGET=200
        REMEDY="A single-file plan this long wants to be a folder: INDEX.md plus one phase file per phase." ;;
      *) shopt -u nocasematch; exit 0 ;;
    esac ;;
esac
shopt -u nocasematch

[ -f "$FILE_N" ] || exit 0
# `grep -ac`, not `wc -l`: wc counts newline BYTES, so an unterminated last line
# reads one short. `-a` stops grep's binary heuristic miscounting a stray NUL.
LINES=$(grep -ac '' "$FILE_N" 2>/dev/null)
LINES=${LINES// /}
case "$LINES" in ''|*[!0-9]*) exit 0 ;; esac

# Ratchet state: the count this file was last warned at. Sanitised path, not a
# hash — bash has no builtin digest and a collision costs one warning, never a
# wrong count. Keeping `.`, `-` and `_` matters: collapsing every non-alphanumeric
# made Docs/Plan/a-b/INDEX.md and Docs/Plan/a_b/INDEX.md the same key.
STATE_DIR="${TMPDIR:-/tmp}/my-claude-setup-budget"
KEY=${FILE_N//[^A-Za-z0-9._-]/_}
# Guarded: `${KEY: -120}` on a SHORTER key yields "", which made MARK the state
# directory itself — the write failed and the ratchet silently never engaged.
[ ${#KEY} -gt 120 ] && KEY=${KEY: -120}
MARK="$STATE_DIR/$KEY"

# Trust the state directory, or don't use it. The mark path is predictable, so on
# a shared /tmp another user could plant a symlink and have the write below
# truncate its target. Guarding the mark file alone is a race; guarding the
# DIRECTORY is not — nobody without write permission on it can put anything
# there. `-O`/`-L` are builtins. Untrusted means no ratchet, not no warning.
STATE_OK=1
mkdir -p -m 700 "$STATE_DIR" 2>/dev/null
{ [ -d "$STATE_DIR" ] && [ ! -L "$STATE_DIR" ] && [ -O "$STATE_DIR" ]; } || STATE_OK=0

if [ "$LINES" -le "$BUDGET" ]; then
  # Clearing the mark is what lets a file cut to size warn again if it regrows.
  [ "$STATE_OK" = 1 ] && rm -f -- "$MARK" 2>/dev/null
  exit 0
fi

LAST=0
# The mark has no trailing newline, so read returns non-zero having set LAST.
if [ "$STATE_OK" = 1 ] && [ -f "$MARK" ]; then read -r LAST < "$MARK" 2>/dev/null; fi
case "$LAST" in ''|*[!0-9]*) LAST=0 ;; esac

[ "$LINES" -le "$LAST" ] && exit 0

if [ "$STATE_OK" = 1 ]; then
  [ -L "$MARK" ] && rm -f -- "$MARK" 2>/dev/null
  printf '%s' "$LINES" > "$MARK" 2>/dev/null
fi

# hookSpecificOutput WITH hookEventName — a bare additionalContext is discarded
# silently. The path is the only field that can carry a character JSON cares
# about: backslashes are already gone, quotes are escaped, and the whole C0 range
# is dropped, since JSON forbids all 32 and a POSIX filename may hold any of them.
# Dropped rather than escaped — a slightly mangled path still says the true thing,
# and a warning that never arrives says nothing.
ESCAPED=${FILE_N//\"/\\\"}
ESCAPED=${ESCAPED//[[:cntrl:]]/ }   # POSIX class, not a byte range: ranges are collation-dependent.

printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' \
"Doc budget: $ESCAPED is now $LINES lines against a budget of $BUDGET. $REMEDY Cut it before moving on. If the overage is deliberate, say why in one line and carry on; this will not warn again until the file grows further."

exit 0
