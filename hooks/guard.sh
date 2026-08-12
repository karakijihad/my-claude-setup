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
#
# Every match below is bash's own [[ =~ ]], not `echo | grep`. The patterns are
# unchanged; only the engine is. Profiled on Windows 2026-08-12, this hook cost
# ~930ms on an ordinary Bash call, and ~810ms of that was nine process spawns at
# 90-200ms each — six greps that almost always say no, plus three interpreter
# calls to read three JSON fields. bash's regex engine is a builtin and the
# fields now come from one parse_all call, which takes the same work to ~200ms.
# Nothing here is a hot loop; it is spawn count, and spawn count only.
#
# ERE, not PCRE: bash has no \s and no \b, so those are [[:space:]] and an
# explicit ([[:space:]]|$). Patterns live in single-quoted variables and are
# matched unquoted — quoting the right-hand side of =~ makes bash match it as a
# literal string, which would silently disable every check in this file.

INPUT=$(cat)
. "$(dirname "$0")/lib-parse.sh"

parse_all

if [ -n "$CMD" ]; then
  # --- Bash ---------------------------------------------------------------
  RE_DESTRUCTIVE='rm[[:space:]]+-[a-z]*r[a-z]*f[a-z]*[[:space:]]+(/|~|\*|"?\$HOME)|rm[[:space:]]+-[a-z]*f[a-z]*r[a-z]*[[:space:]]+(/|~|\*)|DROP[[:space:]]+(TABLE|DATABASE)|TRUNCATE[[:space:]]+TABLE|push[[:space:]]+--force([[:space:]]|$)|push[[:space:]]+-f([[:space:]]|$)|git[[:space:]]+reset[[:space:]]+--hard|git[[:space:]]+clean[[:space:]]+-[a-z]*f|git[[:space:]]+checkout[[:space:]]+--[[:space:]]'

  shopt -s nocasematch
  if [[ $CMD =~ $RE_DESTRUCTIVE ]]; then
    shopt -u nocasematch
    echo "BLOCKED: Destructive command. Review and run manually if intended." >&2
    exit 2
  fi
  shopt -u nocasematch

  # Case-sensitive, unlike the block above: `git branch -D` force-deletes an
  # unmerged branch, `git branch -d` refuses to. Folding case caught the safe
  # one too, so tidying up after a merge tripped the guard.
  RE_BRANCH_FORCE_DELETE='git[[:space:]]+branch[[:space:]]+(-[a-zA-Z]*D|--delete[[:space:]]+--force|--force[[:space:]]+--delete)'
  if [[ $CMD =~ $RE_BRANCH_FORCE_DELETE ]]; then
    echo "BLOCKED: Force-deletes an unmerged branch. Use -d, or run manually if intended." >&2
    exit 2
  fi

  # Supply chain. A remote script piped straight into a shell runs code nobody
  # read, from a URL that can serve something different the second time.
  # security-protocol §06 argues this in prose; here it is enforceable.
  RE_PIPE_TO_SHELL='(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|k)?sh'
  shopt -s nocasematch
  if [[ $CMD =~ $RE_PIPE_TO_SHELL ]]; then
    shopt -u nocasematch
    echo "BLOCKED: Pipes a remote script into a shell. Download it, read it, then run it." >&2
    exit 2
  fi
  shopt -u nocasematch

  # Both of these defeat a control that exists on purpose. -f stages a file
  # .gitignore was excluding, which is the usual way a .env reaches a remote;
  # --no-verify skips the git hooks that would have caught it on the way out.
  RE_ADD_FORCE='git[[:space:]]+add[[:space:]]+(-[a-zA-Z]*f|--force)'
  if [[ $CMD =~ $RE_ADD_FORCE ]]; then
    echo "BLOCKED: 'git add -f' stages a file .gitignore excluded. Check what it is first." >&2
    exit 2
  fi

  RE_COMMIT_SKIPS_HOOKS='git[[:space:]]+commit[^|;&]*([[:space:]]-n([[:space:]]|$)|--no-verify|--no-gpg-sign)'
  if [[ $CMD =~ $RE_COMMIT_SKIPS_HOOKS ]]; then
    echo "BLOCKED: Commit skips git's own hooks. Fix what the hook objects to instead." >&2
    exit 2
  fi

  # Secret scan applies to commits only, and reads the staged diff — not the
  # command text — so "fix: handle expired tokens" is not a false positive.
  # The greps below survive on purpose: this branch runs on a commit, which is
  # rare and already pays for a `git diff`, and scanning a whole diff line by
  # line in bash would be slower than one grep over it.
  RE_IS_COMMIT='(^|&&|;)[[:space:]]*git[[:space:]]+([a-z-]+[[:space:]]+)*commit'
  [[ $CMD =~ $RE_IS_COMMIT ]] || exit 0

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
[ -z "$FILE" ] && FILE="$NBPATH"

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
