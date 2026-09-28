#!/bin/bash
# Find a working Python 3 and exec the given script with it.
#
# `python3` is not reliably a real interpreter. On Windows it is usually the
# 0-byte Microsoft Store alias stub in %LOCALAPPDATA%\Microsoft\WindowsApps,
# which exits 9009 without running anything — and winget/python.org builds
# ship python.exe and py.exe but no python3.exe, so installing Python does
# not displace it. Probe by executing each candidate rather than trusting
# that the name resolves.
#
# The probe is a full interpreter start, which under on-launch AV scanning
# costs seconds, so its answer is cached: the interpreter's own path, keyed on
# the PATH it was found under. Reading the cache is builtins only — no spawn.
# A changed PATH or a vanished interpreter re-probes.
#
# Any script in this plugin that needs Python goes through here.
set -u

CACHE="${HOME:-}/.claude/.my-claude-setup-python"

if [ -n "${HOME:-}" ] && { IFS= read -r c_path; IFS= read -r c_exe; } 2>/dev/null < "$CACHE" \
   && [ "$c_path" = "$PATH" ] && [ -x "$c_exe" ]; then
    exec "$c_exe" "$@"
fi

probe() { "$@" -c 'import sys; print(sys.version_info[0]); print(sys.executable)' 2>/dev/null; }

for cmd in "python3" "python" "py -3"; do
    # shellcheck disable=SC2086
    out=$(probe $cmd) || continue
    out=${out//$'\r'/}
    [ "${out%%$'\n'*}" = "3" ] || continue
    exe=${out#*$'\n'}
    if [ -n "${HOME:-}" ] && [ -x "$exe" ]; then
        { printf '%s\n%s\n' "$PATH" "$exe" > "$CACHE"; } 2>/dev/null
        exec "$exe" "$@"
    fi
    # shellcheck disable=SC2086
    exec $cmd "$@"
done

echo "my-claude-setup: no working Python 3 interpreter found." >&2
echo "  tried: python3, python, py -3" >&2
exit 1
