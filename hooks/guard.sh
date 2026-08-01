#!/bin/bash
# PreToolUse (Bash|Edit|Write|NotebookEdit — keep hooks.json's matcher in sync).
# Exit 2 = block.
#
# One script for what used to be three (block-destructive, check-secrets,
# protect-files). Those each spawned a shell and a JSON parse on *every* Bash
# call just to decide they had nothing to do. This dispatches on which field is
# present, so an Edit never pays for the Bash checks and vice versa.
#
# Covers the confirmation-gated operations in security-protocol §7.2 / §7.6.

INPUT=$(cat)
. "$(dirname "$0")/lib-parse.sh"

CMD=$(parse_field "tool_input.command")

if [ -n "$CMD" ]; then
  # --- Bash ---------------------------------------------------------------
  if echo "$CMD" | grep -qiE \
    "rm\s+-[a-z]*r[a-z]*f[a-z]*\s+(/|~|\*|\"?\\\$HOME)|rm\s+-[a-z]*f[a-z]*r[a-z]*\s+(/|~|\*)|DROP\s+(TABLE|DATABASE)|TRUNCATE\s+TABLE|push\s+--force(\s|$)|push\s+-f\b|git\s+reset\s+--hard|git\s+clean\s+-[a-z]*f|git\s+checkout\s+--\s"; then
    echo "BLOCKED: Destructive command. Review and run manually if intended." >&2
    exit 2
  fi

  # Case-sensitive, unlike the block above: `git branch -D` force-deletes an
  # unmerged branch, `git branch -d` refuses to. Folding case caught the safe
  # one too, so tidying up after a merge tripped the guard.
  if echo "$CMD" | grep -qE "git\s+branch\s+(-[a-zA-Z]*D|--delete\s+--force|--force\s+--delete)"; then
    echo "BLOCKED: Force-deletes an unmerged branch. Use -d, or run manually if intended." >&2
    exit 2
  fi

  # Secret scan applies to commits only, and reads the staged diff — not the
  # command text — so "fix: handle expired tokens" is not a false positive.
  echo "$CMD" | grep -qE "(^|&&|;)\s*git\s+([a-z-]+\s+)*commit" || exit 0

  ADDED=$(git diff --cached --no-color 2>/dev/null | grep -E "^\+" | grep -v '^+++')
  [ -z "$ADDED" ] && exit 0

  if echo "$ADDED" | grep -qiE "(api[_-]?key|secret|token|passw(or)?d|private[_-]?key|client[_-]?secret)[\"']?\s*[:=]\s*[\"'][A-Za-z0-9_/+=.\-]{12,}[\"']"; then
    echo "BLOCKED: Value-shaped secret in staged diff. Move it to .env, then commit." >&2
    exit 2
  fi

  if echo "$ADDED" | grep -qE "AKIA[0-9A-Z]{16}|-----BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----|ghp_[A-Za-z0-9]{36}|sk-[A-Za-z0-9]{20,}"; then
    echo "BLOCKED: Credential material in staged diff (AWS key / private key / access token)." >&2
    exit 2
  fi

  exit 0
fi

# --- Edit / Write / NotebookEdit ------------------------------------------
FILE=$(parse_field "tool_input.file_path")
[ -z "$FILE" ] && FILE=$(parse_field "tool_input.notebook_path")

if [ -z "$FILE" ]; then
  # Every tool this hook matches carries a command, a file_path, or a
  # notebook_path. Finding none of them in a non-empty payload means the parser
  # failed, not that the event was empty. Still exit 0 — a hook that blocks on
  # its own failure is worse — but say so: a silent skip here is a guard that
  # has stopped guarding without anyone noticing.
  [ -n "$INPUT" ] && echo "my-claude-setup: guard.sh could not parse the hook payload; checks were SKIPPED. Install jq or a working Python 3." >&2
  exit 0
fi

case "$(basename "$FILE")" in
  # security-protocol §04-Data requires an example env file to exist.
  .env.example|.env.sample|.env.template) exit 0 ;;
  .env|.env.*|package-lock.json|yarn.lock|pnpm-lock.yaml)
    echo "BLOCKED: Protected file. Edit manually if intended: $FILE" >&2
    exit 2 ;;
esac

case "$FILE" in
  */.git/*|*\\.git\\*)
    echo "BLOCKED: Refusing to edit inside .git/: $FILE" >&2
    exit 2 ;;
esac

exit 0
