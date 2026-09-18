#!/bin/bash
# PostToolUse (Bash|PowerShell — keep hooks.json's matcher in sync). Never
# blocks: this event cannot stop a tool call that already ran, so every path
# exits 0.
#
# Why a hook at all. Everything else in git-protocol happens while the work is
# in hand; CI resolves minutes after the push, by which point the session has
# usually declared victory. A prose rule that has to fire *after* the work feels
# finished is the kind that loses to context pressure — the same reason the
# destructive-command rule ended up in guard.sh rather than in a skill.
#
# Fires on every Bash/PowerShell call, so the cheap rejections come first.

# `read`, not `$(cat)`: cat is an external binary, so this forked and exec'd on
# every call — the one spawn every payload paid before any check ran. `-d ''`
# reads to EOF and returns non-zero having set INPUT, which is why the status is
# not checked. See budget.sh for the same note.
IFS= read -r -d '' INPUT
# `${0%/*}`, not `$(dirname "$0")` — one fewer process spawn on every tool
# call. See lib-parse.sh for the measurement; the guard is the no-slash case.
_HOOK_DIR="${0%/*}"; [ "$_HOOK_DIR" = "$0" ] && _HOOK_DIR="."
. "$_HOOK_DIR/lib-parse.sh"

parse_all
[ -z "$CMD" ] && exit 0

# `git push`, `git --no-pager push`, and the same chained after && or ; or a
# newline. The option-repeat group keeps `git log --grep push` out: after `git`,
# a bare word that isn't an option ends the match.
#
# `git` must also START a command. Without the leading boundary the pattern
# matched the text anywhere in the payload, so `echo git push`, a heredoc
# mentioning it, or a test fixture holding the string all announced a push. A
# newline is in the boundary class and a plain space is not — several git
# commands in one Bash call, one per line, is the commonest shape there is, and
# leaving the newline out silently broke exactly the case this hook is for.
#
# `[[ =~ ]]`, not `echo | grep`: that pipeline forked twice on every Bash call.
# The pattern must stay in a variable and unquoted — quoting it inside `[[ ]]`
# makes bash match it literally.
PUSH_RE="(^|[;&|("$'\n'"]|&&|\|\|)[[:space:]]*git([[:space:]]+-[^[:space:]]+)*[[:space:]]+push([[:space:]]|$)"
[[ $CMD =~ $PUSH_RE ]] || exit 0

# A push aimed somewhere else is not this repo's push. `-C` and `--git-dir` run
# here but act there, and reading the caller's SHA for one names a commit that
# was never pushed — a CI pointer to the wrong run. Silence beats a confident
# wrong answer, and the hook has nothing else to offer for another repo.
[[ $CMD =~ (^|[[:space:]])(-C|--git-dir)([[:space:]]|=) ]] && exit 0

SHA=$(git rev-parse HEAD 2>/dev/null) || exit 0
[ -z "$SHA" ] && exit 0

# No provider detection. Absence of a config file is not absence of CI — hosted
# checks and required status checks leave nothing in the tree — and guessing
# from seven filenames produced a confident CLI suggestion that was wrong
# whenever it mattered. The repo's own check command belongs in its CLAUDE.md
# under `## CI`, which git-protocol says to record once; this hook points there.
#
# It does not claim the push landed: nothing here has verified that, and a
# session reads "Push landed" as fact and goes looking for a run that may not
# exist.
#
# printf template rather than assembled JSON: SHA is hex and everything else is
# a literal, so nothing here is left that JSON cares about. A malformed object
# would not be an error — Claude Code discards it silently and the reminder
# simply vanishes.
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' \
"A push ran from this repo at $SHA. Check CI for that SHA before calling the work done, using the check command in this repo's CLAUDE.md under '## CI' (for GitHub: gh run list -c $SHA -L 5). Match the run by SHA — a run on an earlier commit is not evidence. Report the outcome as green / red / cancelled / skipped / queued / unavailable; only green passes. Don't poll: finish the remaining work, then check once. If it is still running when the work is done, tell the user they can type '/loop 2m <the check command>' and stop watching it yourself."

exit 0
