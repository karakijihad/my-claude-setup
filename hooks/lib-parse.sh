# Sourced by hooks. Provides parse_all — tool_input command / file_path /
# notebook_path, read from the stdin JSON already in $INPUT. jq if present,
# else a Python located by py.sh. Empty strings on failure — every caller must
# fail open.
#
# It probes jq by *running* it rather than asking whether the name resolves:
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
