#!/bin/bash
# Notification hook. Desktop notification on Linux (notify-send), macOS (osascript),
# and Windows (PowerShell balloon tip). Never blocks — always exits 0.

INPUT=$(cat)
. "$(dirname "$0")/lib-parse.sh"
MSG=$(parse_field "message")
[ -z "$MSG" ] && exit 0

# Sanitize once, for every backend. Two of the three don't take the message as a
# literal — they interpolate it into AppleScript or PowerShell *source* — so a
# quote character in the message ends the string and the rest is evaluated as
# code. The message is model-influenced text, which security-protocol §7.1 says
# to treat as untrusted, so strip everything either language can re-enter on:
# quotes, backtick, dollar, backslash, and control characters.
SAFE_MSG=$(printf '%s' "$MSG" | tr -d '`$\\"'"'" | tr -d '\000-\037' | cut -c1-200)
[ -z "$SAFE_MSG" ] && exit 0

if command -v notify-send >/dev/null 2>&1; then
  # notify-send takes argv, not source — the unsanitized message is safe here.
  notify-send "Claude Code" "$MSG"
elif command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"$SAFE_MSG\" with title \"Claude Code\""
elif command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -NoProfile -NonInteractive -Command "
    Add-Type -AssemblyName System.Windows.Forms;
    Add-Type -AssemblyName System.Drawing;
    \$n = New-Object System.Windows.Forms.NotifyIcon;
    \$n.Icon = [System.Drawing.SystemIcons]::Information;
    \$n.Visible = \$true;
    \$n.ShowBalloonTip(5000, 'Claude Code', '$SAFE_MSG', 'Info');
    Start-Sleep -Seconds 6;
    \$n.Dispose()" >/dev/null 2>&1 &
fi

exit 0
