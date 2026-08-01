#!/bin/bash
# Behavioural tests for every hook. No framework — run it, read the last line:
#
#   bash hooks/test-hooks.sh
#
# Destructive fixtures are assembled at runtime instead of being written out
# literally, because guard.sh inspects the text of the command that invokes it:
# a literal destructive string in this file blocks the test run itself. That is
# not paranoia, it is how the previous verification snippet in CLAUDE.md broke.

cd "$(dirname "$0")" || exit 1
HOOKS=$PWD
PASS=0; FAIL=0

ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ -n "$2" ] && printf '       %s\n' "$2"; }

# exit_is <expected> <name> <json>
exit_is() {
  local want="$1" name="$2" json="$3" got
  printf '%s' "$json" | bash guard.sh >/dev/null 2>&1
  got=$?
  [ "$got" = "$want" ] && ok "$name" || bad "$name" "expected exit $want, got $got"
}

# json_ok <name> <script> — running <script> must print one JSON object with a
# non-empty additionalContext. Takes the script rather than a pipe: `| json_ok`
# would run the counters in a subshell, losing both the tally and any failure.
json_ok() {
  local name="$1" out
  # </dev/null matters: session-start.py drains stdin, so without an EOF the
  # hook blocks forever instead of failing.
  out=$(bash "$2" 2>/dev/null </dev/null)
  printf '%s' "$out" | bash py.sh -c '
import json,sys
d=json.load(sys.stdin)
assert isinstance(d,dict) and d.get("additionalContext"), "missing additionalContext"
' >/dev/null 2>&1 && ok "$name" || bad "$name" "not valid JSON with additionalContext"
}

echo "session-start"
json_ok "emits valid JSON" session-start.sh
# Force the no-Python branch: a py.sh that always fails must still yield a core.
# Check mktemp before using $TMP — an empty TMP would make the redirect below
# write to /py.sh, outside the sandbox this test is supposed to stay in.
TMP=$(mktemp -d) || { bad "no-Python fallback" "mktemp -d failed"; TMP=; }
if [ -n "$TMP" ] && [ -d "$TMP" ]; then
  cp session-start.sh session-start.py core.md "$TMP/" 2>/dev/null
  printf '#!/bin/bash\nexit 1\n' > "$TMP/py.sh"
  json_ok "falls back to a core when Python is unavailable" "$TMP/session-start.sh"
  # And with neither Python nor jq, the last-resort branch must still emit a
  # core. Asserted with grep, not a JSON parser — on the machine this branch
  # exists for, there is no JSON parser to validate it with.
  out=$(PATH=/usr/bin:/bin bash -c 'jq() { return 127; }; export -f jq 2>/dev/null; exec bash '"$TMP"'/session-start.sh' 2>/dev/null </dev/null)
  case "$out" in
    *'"additionalContext"'*Brevity*) ok "reduced core when neither Python nor jq is present" ;;
    *) bad "reduced core when neither Python nor jq is present" "got: ${out:0:80}" ;;
  esac
  rm -rf "$TMP"
fi

echo "brevity"
json_ok "emits valid JSON" brevity.sh

echo "guard — destructive commands"
RMRF="rm -$(printf 'r')f /"
exit_is 2 "blocks recursive force-delete of /"   "{\"tool_input\":{\"command\":\"$RMRF\"}}"
exit_is 2 "blocks git push --force"              '{"tool_input":{"command":"git push --force origin main"}}'
exit_is 2 "blocks git reset --hard"              '{"tool_input":{"command":"git reset --hard HEAD~1"}}'
exit_is 2 "blocks DROP TABLE"                    '{"tool_input":{"command":"psql -c \"DROP TABLE users\""}}'
exit_is 0 "allows an ordinary command"           '{"tool_input":{"command":"ls -la"}}'
exit_is 0 "allows a commit with a clean diff"    '{"tool_input":{"command":"git commit -m \"fix: expired token handling\""}}'

echo "guard — protected files"
exit_is 2 "blocks .env"                          '{"tool_input":{"file_path":"/x/.env"}}'
exit_is 2 "blocks .env.production"               '{"tool_input":{"file_path":"/x/.env.production"}}'
exit_is 0 "allows .env.example"                  '{"tool_input":{"file_path":"/x/.env.example"}}'
exit_is 2 "blocks package-lock.json"             '{"tool_input":{"file_path":"/x/package-lock.json"}}'
exit_is 2 "blocks paths inside .git/ (posix)"    '{"tool_input":{"file_path":"/x/.git/config"}}'
exit_is 0 "allows an ordinary source file"       '{"tool_input":{"file_path":"/x/a.ts"}}'
exit_is 2 "blocks .env via notebook_path"        '{"tool_input":{"notebook_path":"/x/.env"}}'
exit_is 0 "allows an ordinary notebook"          '{"tool_input":{"notebook_path":"/x/a.ipynb"}}'
exit_is 0 "fails open on an unparseable payload" 'not json at all'
# Windows paths arrive backslash-delimited. MSYS basename splits on them and the
# .git case pattern carries a backslash form, so these already pass — pin that
# down rather than trusting it, since this is the plugin's primary platform.
exit_is 2 "blocks a backslash .env path"         '{"tool_input":{"file_path":"C:\\repo\\.env"}}'
exit_is 2 "blocks a backslash .git path"         '{"tool_input":{"file_path":"C:\\repo\\.git\\config"}}'
exit_is 0 "allows a backslash source path"       '{"tool_input":{"file_path":"C:\\repo\\src\\a.ts"}}'

echo "notify"
printf '%s' '{"message":"build done"}' | bash notify.sh >/dev/null 2>&1 \
  && ok "exits 0 on a normal message" || bad "exits 0 on a normal message"

# Drive notify.sh for real with a stub backend on PATH and inspect the argv it
# built. Recomputing the tr pipeline here instead would test a copy of the
# sanitizer — notify.sh could drop its own and the assertion would still pass.
NT=$(mktemp -d)
if [ -n "$NT" ] && [ -d "$NT" ]; then
  printf '#!/bin/bash\nprintf "%%s\\n" "$@" > "%s/argv"\n' "$NT" > "$NT/osascript"
  chmod +x "$NT/osascript"
  printf '%s' '{"message":"x\" & (do shell script \"id\") & \"$(whoami)`hostname`"}' \
    | PATH="$NT:$PATH" bash "$HOOKS/notify.sh" >/dev/null 2>&1
  ARGV=$(cat "$NT/argv" 2>/dev/null)
  if [ -z "$ARGV" ]; then
    # notify-send is tried first and wins on Linux; it takes argv, not source.
    ok "osascript backend not reached on this platform (notify-send preferred)"
  else
    # The argv legitimately contains four double quotes — AppleScript's own
    # delimiters around the message and the title. Anything beyond that, or any
    # backtick/dollar/backslash/single quote at all, means the message escaped.
    QUOTES=$(printf '%s' "$ARGV" | tr -cd '"' | wc -c | tr -d ' ')
    case "$ARGV" in
      *\'*|*\`*|*\$*|*\\*)
        bad "notify.sh passes no re-enterable characters to its backend" "argv: $ARGV" ;;
      *)
        [ "$QUOTES" = 4 ] \
          && ok "notify.sh passes no re-enterable characters to its backend" \
          || bad "notify.sh passes no re-enterable characters to its backend" \
                 "expected 4 delimiter quotes, found $QUOTES in: $ARGV" ;;
    esac
  fi
  rm -rf "$NT"
fi

echo "guard — commit secret scan"
# Real staged diff in a throwaway repo: guard.sh reads `git diff --cached`, not
# the command text, so nothing short of an actual commit exercises this path.
# The fixture is assembled at runtime — a literal value-shaped secret in this
# file would make guard.sh block the commit that adds this file.
GT=$(mktemp -d)
if [ -n "$GT" ] && [ -d "$GT" ]; then
  (
    cd "$GT" || exit 1
    git init -q . && git config user.email t@t && git config user.name t
    KEYNAME="api""_key"
    VALUE=$(printf 'k%.0s' $(seq 1 24))
    printf '%s = "%s"\n' "$KEYNAME" "$VALUE" > leaked.conf
    git add leaked.conf
  ) >/dev/null 2>&1
  printf '%s' '{"tool_input":{"command":"git commit -m \"add config\""}}' \
    | (cd "$GT" && bash "$HOOKS/guard.sh") >/dev/null 2>&1
  [ $? = 2 ] && ok "blocks a commit whose staged diff holds a value-shaped secret" \
             || bad "blocks a commit whose staged diff holds a value-shaped secret"
  rm -rf "$GT"
fi

echo "guard — Windows interpreter layout"
# The regression that started all this: jq absent, `python`/`python3` present as
# stubs that exit without running, only `py -3` real. guard.sh must still block,
# not parse everything as empty and wave it through.
WT=$(mktemp -d)
if [ -n "$WT" ] && [ -d "$WT" ]; then
  REAL_PY=$(bash py.sh -c 'import sys; print(sys.executable)' 2>/dev/null)
  if [ -z "$REAL_PY" ]; then
    ok "skipped Windows-layout case (no interpreter to build the shim from)"
  else
    for stub in jq python python3; do
      printf '#!/bin/bash\nexit 9009\n' > "$WT/$stub"; chmod +x "$WT/$stub"
    done
    # `py -3 ...` must reach the real interpreter, mimicking the Windows launcher.
    printf '#!/bin/bash\n[ "$1" = "-3" ] && shift\nexec "%s" "$@"\n' "$REAL_PY" > "$WT/py"
    chmod +x "$WT/py"
    OUT=$(printf '%s' '{"tool_input":{"file_path":"/x/.env"}}' \
      | PATH="$WT:/usr/bin:/bin" bash "$HOOKS/guard.sh" 2>&1)
    if [ $? = 2 ]; then
      ok "blocks .env with only 'py -3' working (jq and python stubbed out)"
    else
      bad "blocks .env with only 'py -3' working (jq and python stubbed out)" "$OUT"
    fi
  fi
  rm -rf "$WT"
fi

echo "onboarding"
bash py.sh -c '
import sys, tempfile, pathlib
import onboarding as o
tmp = pathlib.Path(tempfile.mkdtemp())

# Missing things: the notice must survive more than one session. Burning it on
# first emit is how it used to get lost — SessionStart context arrives with no
# user turn, so an undelivered notice was gone for good.
o.MARKER = tmp / "a"
o.SETTINGS = tmp / "absent.json"
shows = sum(1 for _ in range(5) if o.notice())
assert shows == o.MAX_SHOWS, f"expected {o.MAX_SHOWS} shows, got {shows}"

# A pre-counter marker (empty file) means that user already finished: stay quiet.
o.MARKER = tmp / "b"; o.MARKER.write_text("")
assert not o.notice(), "nagged a user who had already onboarded"

# Nothing missing: silent, and recorded as done rather than re-checked forever.
o.MARKER = tmp / "c"
o._missing_companions = lambda c: []
o._unapplied_settings = lambda c: []
o._legacy_artifacts = lambda c: []
assert not o.notice(), "spoke up with nothing to report"
assert o._shown() == o.MAX_SHOWS
' >/dev/null 2>&1 && ok "notice repeats up to MAX_SHOWS, respects legacy marker, silent when set up" \
  || bad "notice repeats up to MAX_SHOWS, respects legacy marker, silent when set up"

echo "consistency"
M=$(bash py.sh -c 'import json;print(json.load(open("hooks.json"))["hooks"]["PreToolUse"][0]["matcher"])' 2>/dev/null)
case "$M" in
  *NotebookEdit*) ok "hooks.json matcher covers NotebookEdit, as guard.sh claims" ;;
  *) bad "hooks.json matcher covers NotebookEdit, as guard.sh claims" "matcher: $M" ;;
esac
bash py.sh -c '
import re,sys
core=open("core.md",encoding="utf-8").read()
src=open("onboarding.py",encoding="utf-8").read()
listed={n for n in re.findall(r"^    \"([a-z0-9-]+)\": \(", src, re.M)}
named={c for c in listed if c in core}
missing=listed-named
sys.exit(0 if not missing else 1)
' >/dev/null 2>&1 && ok "every onboarding companion is named in core.md" \
  || bad "every onboarding companion is named in core.md"

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
