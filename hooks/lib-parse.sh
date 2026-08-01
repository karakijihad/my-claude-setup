# Sourced by hooks. Provides parse_field <json-path> — reads stdin JSON from $INPUT.
# jq if present, else python, else python3. Empty string on failure.
# Path syntax: dot-separated keys, e.g. "tool_input.command" or "message".

parse_field() {
  local path="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$INPUT" | jq -r ".${path} // \"\"" 2>/dev/null
    return
  fi
  local py="
import json,sys,io,functools
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
  if command -v python >/dev/null 2>&1; then
    printf '%s' "$INPUT" | python -c "$py" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$INPUT" | python3 -c "$py" 2>/dev/null
  else
    printf ''
  fi
}
