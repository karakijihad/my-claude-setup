#!/bin/bash
# PostToolUse (Bash — keep hooks.json's matcher in sync). Never blocks: this
# event cannot stop a tool call that already ran, so every path exits 0.
#
# Why a hook at all. Everything else in git-protocol happens while the work is
# in hand; CI resolves minutes after the push, by which point the session has
# usually declared victory. A prose rule that has to fire *after* the work feels
# finished is the kind that loses to context pressure — the same reason the
# destructive-command rule ended up in guard.sh rather than in a skill.
#
# Fires on every Bash call, so the cheap rejections come first.

# `read`, not `$(cat)`. `cat` is an external binary, so this forked and exec'd
# on every call — the one spawn every payload paid before any check ran. `-d ''`
# reads to EOF and returns non-zero having set INPUT, which is why the status is
# not checked. See budget.sh for the same note.
IFS= read -r -d '' INPUT
. "$(dirname "$0")/lib-parse.sh"

# parse_all, not parse_field, even though only one of its three fields is wanted
# here. This hook fires on every Bash call, and parse_field paid an interpreter
# spawn per field through its own separate jq-then-Python implementation — the
# exact cost parse_all was written to collapse when guard.sh stopped doing this.
# One extraction, one spawn, and one implementation left to keep correct.
parse_all
[ -z "$CMD" ] && exit 0

# `git push`, `git -C /path push`, `git --no-pager push`, and the same chained
# after && or ;. The option-repeat group is what keeps `git log --grep push`
# out: after `git`, a bare word that isn't an option ends the match.
#
# The separate-argument options are named rather than allowed generically. A
# generic "option, then optionally one non-option word" rule cannot tell `-C /r`
# from `--no-pager log`, and a regex engine only needs one valid decomposition:
# `git --no-pager log --grep push` parsed as (`--no-pager` taking `log`), then
# (`--grep`), then `push` — and the hook announced a landed push for a command
# that never touched the remote. These seven are git's whole set that take their
# value as the next word; every other flag either stands alone or carries its
# value with `=`, and both match the second alternative.
#
# `[[ =~ ]]`, not `echo | grep`: that pipeline forked twice on every Bash call in
# the session, which is the cost this "cheapest rejections first" ordering exists
# to avoid. The pattern must stay in a variable and unquoted — quoting it inside
# `[[ ]]` makes bash match it literally.
# `git` must also start a command. Without the leading boundary the pattern
# matched the literal text anywhere in the payload, so `echo git push`, a heredoc
# mentioning it, or a test fixture containing the string all announced a landed
# push — this hook fired twice on its own test loop while that loop was being
# written. The set is the shell operators that end one command and begin another;
# a quote or a bare space before `git` is not one of them.
# A newline is a command separator too, and leaving it out of the boundary class
# broke the commonest shape there is — several git commands in one Bash call,
# one per line, with no `&&` anywhere:
#
#     git add -A
#     git commit -m ok
#     git push
#
# That matched before this boundary existed and stopped matching after, which
# turned a false-positive fix into a silent false negative on the case the hook
# is actually for. A newline is in the class; a plain space is not, which is what
# still keeps `echo git push` out.
PUSH_OPT="(-C|-c|--git-dir|--work-tree|--namespace|--exec-path|--super-prefix)"
PUSH_RE="(^|[;&|("$'\n'"]|&&|\|\|)[[:space:]]*git([[:space:]]+$PUSH_OPT[[:space:]]+[^[:space:]]+|[[:space:]]+-[^[:space:]]+)*[[:space:]]+push([[:space:]]|$)"
[[ $CMD =~ $PUSH_RE ]] || exit 0
# Only the matched `git … push` span is searched for options below. Searching the
# whole command string reads options belonging to a different git call: in
# `git commit -C HEAD~1 && git push`, `-C` takes a commit, not a path, and the
# hook would have pointed every query at a directory named HEAD~1, failed, and
# gone silent about a push that really happened.
PUSH_SEG=${BASH_REMATCH[0]}

# Which repository was pushed. `git -C /other/repo push` runs in the session's
# cwd but acts somewhere else, and every check below used to ignore that: the
# hook read the *caller's* toplevel, upstream, SHA and branch and announced them
# for a push that landed in another repo entirely — a reminder pointing at a CI
# run for a commit that was never pushed. `--git-dir` is not handled the same
# way on purpose: it names a git directory rather than a work tree, and the
# provider detection below reads files from the work tree, so there is nothing
# reliable to point at. Silence beats a confident wrong answer.
[[ $PUSH_SEG =~ (^|[^[:alnum:]_-])--git-dir([[:space:]]|=) ]] && exit 0
GDIR="."
# The LAST -C, not the first. git applies them cumulatively and an absolute one
# replaces what came before, so `git -C /a -C /b push` pushes /b — while a bash
# `=~` is not global and anchors on the first occurrence, which would have named
# /a and then reported that repository's SHA for a push that landed in the other.
# The leading `.*` is greedy, which drags the match as far right as it can go.
[[ $PUSH_SEG =~ .*(^|[^[:alnum:]_-])-C[[:space:]]+([^[:space:]]+) ]] && GDIR="${BASH_REMATCH[2]}"

ROOT=$(git -C "$GDIR" rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -z "$ROOT" ] && exit 0

# Did the push actually deliver HEAD? A rejected push leaves the branch ahead of
# its upstream, and a reminder to go read CI for a commit the remote never
# received is worse than silence — the run it finds would be someone else's.
# No upstream at all yields an empty count: can't tell, so say it anyway — but
# say it as a maybe. Reporting "Push landed" for a push nobody verified is the
# same failure this block exists to prevent, only quieter: a session reads it as
# fact, goes looking for a run, and finds one belonging to another commit.
AHEAD=$(git -C "$GDIR" rev-list --count '@{u}..HEAD' 2>/dev/null)
[ -n "$AHEAD" ] && [ "$AHEAD" != 0 ] && exit 0
if [ -n "$AHEAD" ]; then
  LANDED="Push landed"
else
  LANDED="A push ran, but there is no upstream to check it against, so whether it landed is unverified"
fi

SHA=$(git -C "$GDIR" rev-parse HEAD 2>/dev/null)
BRANCH=$(git -C "$GDIR" branch --show-current 2>/dev/null)
# Sanitised here, at the source, not just before the printf. It used to be done
# at the end — after `CHECK` had already interpolated a copy of it for the GitLab
# branch, so a quote in a branch name still reached the JSON through that path
# and broke it on exactly one provider. Both characters are dropped rather than
# escaped: a branch name is being quoted into prose here, not round-tripped.
#
# The comment this replaces claimed git's ref rules forbade a quote. They do not:
# `git check-ref-format refs/heads/a"b` exits 0 — the forbidden set is control
# characters, space, `~^:?*[` and backslash.
BRANCH=${BRANCH//\\/}
BRANCH=${BRANCH//\"/}
[ -z "$SHA" ] && exit 0

# Absence of these files is not absence of CI — external Jenkins, hosted checks
# and required status checks leave nothing in the tree. That case belongs to
# /setup, which asks once and records the answer; this
# hook stays quiet rather than guessing.
if [ -n "$(ls -A "$ROOT/.github/workflows" 2>/dev/null)" ]; then
  PROVIDER="GitHub Actions"
  if command -v gh >/dev/null 2>&1; then
    CHECK="gh run list -c $SHA -L 5 --json workflowName,status,conclusion,url"
  else
    # An emitted command that fails is worse than a pointer: the session reads
    # the error as "CI unavailable" and moves on having checked nothing.
    CHECK="gh is not installed — open the repository's Actions tab and find the run for $SHA"
  fi
elif [ -f "$ROOT/.gitlab-ci.yml" ]; then
  PROVIDER="GitLab CI"
  CHECK="glab ci list -b ${BRANCH:-HEAD}, then match the pipeline's commit to $SHA"
else
  for f in Jenkinsfile azure-pipelines.yml .circleci/config.yml .travis.yml \
           bitbucket-pipelines.yml appveyor.yml .buildkite; do
    [ -e "$ROOT/$f" ] && { PROVIDER="$f"; break; }
  done
  [ -z "$PROVIDER" ] && exit 0
  CHECK="no universal CLI for this provider — use the check command recorded in CLAUDE.md, or say plainly that CI status could not be observed"
fi

# printf template rather than assembled JSON: SHA is hex, PROVIDER/CHECK are
# literals chosen above, and BRANCH was sanitised at the point it was read — so
# by here nothing is left that JSON cares about. A malformed object would not be
# an error: Claude Code discards it silently and the reminder simply vanishes.
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' \
"$LANDED: $SHA on ${BRANCH:-a detached HEAD}. CI here is $PROVIDER. Match the run by SHA — a run on an earlier commit is not evidence: $CHECK. Before calling this done, report the outcome as green / red / cancelled / skipped / queued / unavailable; only green passes. Don't poll — finish the remaining work, then check once more. If the run is still going once the work is done, that is the one case for /loop: tell the user they can type '/loop 2m <the check command>' and stop watching it yourself."

exit 0
