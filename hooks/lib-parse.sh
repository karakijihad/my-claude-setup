# Sourced by hooks. Provides parse_field <json-path> — reads stdin JSON from $INPUT.
# jq if present, else a Python located by py.sh. Empty string on failure.
# Path syntax: dot-separated keys, e.g. "tool_input.command" or "message".
#
# Goes through py.sh rather than naming `python`/`python3`, for the reason py.sh
# documents: on Windows those names are usually 0-byte Store stubs that exist on
# PATH and exit 9009 without running. A `command -v` existence check finds one,
# this parser then returns "" for every field, and guard.sh reads that as a tool
# call with no command and no file_path — silently skipping every check it makes.

_LIB_PARSE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Probe jq by running it, not by asking whether the name resolves — the same
# mistake this file made with `python`. A jq on PATH that fails to execute would
# otherwise take the branch, return nothing, and leave guard.sh reading every
# field as absent. Probed once per hook run, then cached.
_LIB_PARSE_JQ=""
_have_jq() {
  if [ -z "$_LIB_PARSE_JQ" ]; then
    if command -v jq >/dev/null 2>&1 && printf '{}' | jq -e . >/dev/null 2>&1; then
      _LIB_PARSE_JQ=yes
    else
      _LIB_PARSE_JQ=no
    fi
  fi
  [ "$_LIB_PARSE_JQ" = yes ]
}

# parse_all — sets CMD, FILE and NBPATH from one interpreter call.
#
# parse_field is fine for a hook that wants one field; guard.sh wants three, and
# paying a separate jq spawn for each is most of what that hook costs. Measured
# on Windows 2026-08-12: process spawns here run 90-200ms apiece, so the three
# calls plus the _have_jq probe were ~370ms of guard.sh's ~930ms. This does the
# probe and the extraction in a single call: jq that is missing or a broken stub
# writes nothing, which lands in the same empty-output branch as a payload that
# genuinely had no fields, and Python gets its turn.
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

parse_field() {
  local path="$1"
  if _have_jq; then
    printf '%s' "$INPUT" | jq -r ".${path} // \"\"" 2>/dev/null
    return
  fi
  local py="
import json,sys,io
sys.stdin=io.TextIOWrapper(sys.stdin.buffer,encoding='utf-8',errors='replace')
sys.stdout=io.TextIOWrapper(sys.stdout.buffer,encoding='utf-8',errors='replace')
try:
    obj=json.loads(sys.stdin.read() or '{}')
    for k in '${path}'.split('.'):
        obj=obj.get(k,'') if isinstance(obj,dict) else ''
    print(obj if isinstance(obj,str) else '')
except Exception:
    print('')
"
  printf '%s' "$INPUT" | bash "$_LIB_PARSE_DIR/py.sh" -c "$py" 2>/dev/null
}
