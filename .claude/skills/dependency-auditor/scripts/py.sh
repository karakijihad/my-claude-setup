#!/bin/bash
# Find a working Python 3 and exec the given script with it.
#
# `python3` is not reliably a real interpreter. On Windows it is usually the
# 0-byte Microsoft Store alias stub in %LOCALAPPDATA%\Microsoft\WindowsApps,
# which exits 9009 without running anything — and winget/python.org builds
# ship python.exe and py.exe but no python3.exe, so installing Python does
# not displace it. Probe by executing each candidate rather than trusting
# that the name resolves.
set -u

probe() { "$@" -c 'import sys; print(sys.version_info[0])' 2>/dev/null; }

for cmd in "python3" "python" "py -3"; do
    # shellcheck disable=SC2086
    [ "$(probe $cmd)" = "3" ] || continue
    # shellcheck disable=SC2086
    exec $cmd "$@"
done

echo "dependency-auditor: no working Python 3 interpreter found." >&2
echo "  tried: python3, python, py -3" >&2
exit 1
