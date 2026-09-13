#!/bin/bash
# PreToolUse (Bash|Edit|Write|NotebookEdit|PowerShell — keep hooks.json's matcher in sync).
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

# `read`, not `$(cat)`. `cat` is an external binary, so this forked and exec'd
# on every call — the one spawn every payload paid before any check ran. `-d ''`
# reads to EOF and returns non-zero having set INPUT, which is why the status is
# not checked. See budget.sh for the same note.
IFS= read -r -d '' INPUT
. "$(dirname "$0")/lib-parse.sh"

parse_all

if [ -n "$CMD" ]; then
  # --- Bash ---------------------------------------------------------------
  # `\b` has no ERE equivalent, and the obvious substitution is wrong. An
  # earlier version of this rewrite rendered `-f\b` as `-f([[:space:]]|$)`,
  # which stops matching the moment the flag is followed by anything that is
  # not a space — so a force-push chained as `;ls` or `&&ls` was silently
  # ALLOWED where the grep original blocked it. `\b` after a word character
  # means "next character is a non-word character, or end of string", and that
  # is what [^a-zA-Z0-9_] spells out.
  RE_WORD_END='([^a-zA-Z0-9_]|$)'
  # `--force` gets the same boundary, which the grep original did NOT give it —
  # it used (\s|$) there, so `push --force;ls` was already getting through
  # before this rewrite existed. Widening it is a deliberate behaviour change:
  # leaving the explicit spelling weaker than the abbreviation would mean the
  # clearer way to write a destructive command is the way that evades the guard.
  #
  # It also newly catches `--force-with-lease`, and that is intended rather than
  # collateral. The lease makes the push safer for *collaborators* — it refuses
  # when the remote moved — but it still rewrites published history, which is
  # what this block asks a human to confirm. Both spellings are blocked, so
  # nothing here nudges anyone from the safe variant toward the blunt one; the
  # user is asked to run either by hand. Pinned by a test, because a reader who
  # assumed it was collateral would "fix" it back.
  #
  # RE_Q: an optional quote in front of an rm target. `"?\$HOME` used to be the
  # only quoted form — it guarded $HOME alone, so `rm -rf "/"` or `rm -rf '~'`
  # went through unquoted-only. Built with a double-quoted assignment because
  # the single-quoted RE_DESTRUCTIVE below cannot hold a literal `'` without
  # the break-and-reopen trick; it is spliced in the same way RE_WORD_END is.
  RE_Q="[\"']?"
  # rm's flags used to be checked only fused into one token (-rf, -fr). `rm -r
  # -f /` and `rm --recursive --force /` split them across two argv words, in
  # either order, and passed. Each order and each spelling gets its own
  # alternative, same reasoning as the two fused-order alternatives already
  # here. git clean's flags get the equivalent split-flag tolerance: up to two
  # unrelated leading flags before the one that carries `f`, which is what
  # `git clean -d -f` and `git clean -x -d -f` actually are.
  RE_DESTRUCTIVE='rm[[:space:]]+-[a-z]*r[a-z]*f[a-z]*[[:space:]]+'"$RE_Q"'(/|~|\*|\$HOME)|rm[[:space:]]+-[a-z]*f[a-z]*r[a-z]*[[:space:]]+'"$RE_Q"'(/|~|\*|\$HOME)|rm[[:space:]]+-[a-z]*r[a-z]*[[:space:]]+-[a-z]*f[a-z]*[[:space:]]+'"$RE_Q"'(/|~|\*|\$HOME)|rm[[:space:]]+-[a-z]*f[a-z]*[[:space:]]+-[a-z]*r[a-z]*[[:space:]]+'"$RE_Q"'(/|~|\*|\$HOME)|rm[[:space:]]+--recursive[[:space:]]+--force[[:space:]]+'"$RE_Q"'(/|~|\*|\$HOME)|rm[[:space:]]+--force[[:space:]]+--recursive[[:space:]]+'"$RE_Q"'(/|~|\*|\$HOME)|DROP[[:space:]]+(TABLE|DATABASE)|TRUNCATE[[:space:]]+TABLE|push[[:space:]]+--force'"$RE_WORD_END"'|push[[:space:]]+-f'"$RE_WORD_END"'|git[[:space:]]+reset[[:space:]]+--hard|git[[:space:]]+clean[[:space:]]+(-[a-z]*[[:space:]]+){0,2}-[a-z]*f|git[[:space:]]+checkout[[:space:]]+--[[:space:]]'

  # PowerShell's rm -rf. Remove-Item takes -Recurse and -Force as separate,
  # independently-ordered named switches with their own abbreviations (down to
  # -r and -fo, the shortest prefixes that stay unambiguous), so it cannot
  # reuse the rm patterns above — those key on one fused or space-split short
  # flag, not named switches. Checked as three independent conditions ANDed
  # together rather than folded into one alternation: an alternation would
  # need every permutation of {cmdlet, -Recurse, -Force, target} enumerated to
  # allow "any order", which is exactly what an AND of three regexes gets for
  # free. Bash's own PowerShell tool carries its script in the same
  # tool_input.command field CMD already comes from — no separate wiring
  # needed once hooks.json's matcher covers the tool.
  RE_PS_RECURSE='-r(e(c(u(r(s(e)?)?)?)?)?)?([^a-zA-Z]|$)'
  RE_PS_FORCE='-fo(r(c(e)?)?)?([^a-zA-Z]|$)'
  # Bounded by whitespace/start/end on both sides so `*.log` and `C:\Users\me`
  # do not read as the bare wildcard or the drive root they merely contain —
  # a dangerous target has to stand alone as its own argument.
  # A quote around the target is the same target — `"C:\"` is how a path with
  # nothing to escape still gets typed — so it is allowed on either side.
  RE_PS_TARGET='(^|[[:space:]])["'"'"']?([A-Za-z]:[\\/]|/|~|\$HOME|\$env:USERPROFILE|\*)[\\/]?\*?["'"'"']?([[:space:]]|$)'

  # The cmdlet by any of its built-in aliases: `rm -Recurse -Force C:\` is the
  # same call, and matching only the full name let it through.
  RE_PS_CMD='(^|[^A-Za-z-])(Remove-Item|ri|rm|rmdir|rd|del|erase)([[:space:]]|$)'

  shopt -s nocasematch
  if [[ $CMD =~ $RE_DESTRUCTIVE ]] || { [[ $CMD =~ $RE_PS_CMD ]] && [[ $CMD =~ $RE_PS_RECURSE ]] && [[ $CMD =~ $RE_PS_FORCE ]] && [[ $CMD =~ $RE_PS_TARGET ]]; }; then
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

  # Same between-words tolerance RE_IS_COMMIT uses below, for the same reason:
  # `git -c foo=bar commit --no-verify` has a global option sitting between
  # `git` and `commit`, and requiring them adjacent missed it. `-c
  # commit.gpgsign=false` and `-c core.hooksPath=...` get their own
  # alternatives rather than folding into the flag group that follows
  # `commit` — both take effect as part of `git` itself, before the
  # subcommand, so the flag they represent can only ever appear ahead of
  # `commit`, never after it.
  RE_COMMIT_SKIPS_HOOKS='git[[:space:]]+([^|;&[:space:]]+[[:space:]]+)*commit[^|;&]*([[:space:]]-n([[:space:]]|$)|--no-verify|--no-gpg-sign)|git[[:space:]]+[^|;&]*-c["'"'"']?[[:space:]]+["'"'"']?commit\.gpgsign=false[^|;&]*commit|git[[:space:]]+[^|;&]*-c["'"'"']?[[:space:]]+["'"'"']?core\.hooksPath=[^|;&]*commit'
  # The quotes above: git strips shell quotes before it reads `-c`, so
  # `-c "commit.gpgsign=false"` is the same override and must block the same.
  if [[ $CMD =~ $RE_COMMIT_SKIPS_HOOKS ]]; then
    echo "BLOCKED: Commit skips git's own hooks. Fix what the hook objects to instead." >&2
    exit 2
  fi

  # Secret scan applies to commits only, and reads the staged diff — not the
  # command text — so "fix: handle expired tokens" is not a false positive.
  # The greps below survive on purpose: this branch runs on a commit, which is
  # rare and already pays for a `git diff`, and scanning a whole diff line by
  # line in bash would be slower than one grep over it.
  # Any non-separator word may sit between git and commit, not just [a-z-]
  # ones: `-c key=value` carries `.` and `=`, and a narrower class skipped the
  # secret scan for every commit written that way.
  RE_IS_COMMIT='(^|&&|;)[[:space:]]*git[[:space:]]+([^|;&[:space:]]+[[:space:]]+)*commit'
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

# Normalise separators before matching. A Windows payload arrives
# backslash-delimited, and `basename` only splits on those under MSYS — GNU
# basename returns "C:\repo\.env" whole, so the .env case below never matches
# and the file is waved through. The guard was therefore protecting .env on
# Windows and not on Linux, from an identical payload. Caught by the first CI
# run: windows-latest 78/0, ubuntu-latest 77/1.
#
# The trade is a file whose *name* genuinely contains a backslash on a POSIX
# box, which this would misread. That is vanishingly rare and errs toward
# blocking, which is the safe direction for a guard.
FILE_N=${FILE//\\//}

# Case-insensitive the way the Bash checks above are: Windows treats .ENV,
# Package-Lock.json and /.GIT/ as the same paths as their lowercase spellings,
# and a case-sensitive `case` here waved all three through. Turned off before
# every exit in this region, not just at the bottom — an option left set past
# the last check that needs it is a latent bug for the next one added here.
shopt -s nocasematch
case "$(basename "$FILE_N")" in
  # security-protocol §04-Data requires an example env file to exist.
  .env.example|.env.sample|.env.template) shopt -u nocasematch; exit 0 ;;
  .env|.env.*|package-lock.json|yarn.lock|pnpm-lock.yaml)
    shopt -u nocasematch
    echo "BLOCKED: Protected file. Edit manually if intended: $FILE" >&2
    exit 2 ;;
esac

case "$FILE_N" in
  */.git/*)
    shopt -u nocasematch
    echo "BLOCKED: Refusing to edit inside .git/: $FILE" >&2
    exit 2 ;;
esac
shopt -u nocasematch

exit 0
