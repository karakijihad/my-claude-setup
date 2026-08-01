#!/bin/bash
# Notification hook. Desktop notification on Linux (notify-send), macOS (osascript),
# and Windows (PowerShell balloon tip). Never blocks — always exits 0.

INPUT=$(cat)
. "$(dirname "$0")/lib-parse.sh"
MSG=$(parse_field "message")
[ -z "$MSG" ] && exit 0

if command -v notify-send >/dev/null 2>&1; then
  notify-send "Claude Code" "$MSG"
elif command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"$MSG\" with title \"Claude Code\""
elif command -v powershell.exe >/dev/null 2>&1; then
  SAFE_MSG=$(printf '%s' "$MSG" | tr -d "'\"\`" | cut -c1-200)
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
