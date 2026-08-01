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
