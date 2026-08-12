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

INPUT=$(cat)
. "$(dirname "$0")/lib-parse.sh"

CMD=$(parse_field "tool_input.command")
[ -z "$CMD" ] && exit 0

# `git push`, `git -C /path push`, `git --no-pager push`, and the same chained
# after && or ;. The option-repeat group is what keeps `git log --grep push`
# out: after `git`, a bare word that isn't an option ends the match.
echo "$CMD" | grep -qE "git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-][^[:space:]]*)?)*[[:space:]]+push([[:space:]]|$)" || exit 0

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -z "$ROOT" ] && exit 0

# Did the push actually deliver HEAD? A rejected push leaves the branch ahead of
# its upstream, and a reminder to go read CI for a commit the remote never
# received is worse than silence — the run it finds would be someone else's.
# No upstream at all yields an empty count: can't tell, so say it anyway.
AHEAD=$(git rev-list --count '@{u}..HEAD' 2>/dev/null)
[ -n "$AHEAD" ] && [ "$AHEAD" != 0 ] && exit 0

SHA=$(git rev-parse HEAD 2>/dev/null)
BRANCH=$(git branch --show-current 2>/dev/null)
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

# printf template rather than assembled JSON: BRANCH and SHA cannot contain a
# quote or a backslash (git's ref rules and hex), and PROVIDER/CHECK are literals
# chosen above, so there is nothing here that needs escaping.
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' \
"Push landed: $SHA on ${BRANCH:-a detached HEAD}. CI here is $PROVIDER. Match the run by SHA — a run on an earlier commit is not evidence: $CHECK. Before calling this done, report the outcome as green / red / cancelled / skipped / queued / unavailable; only green passes. Don't poll — finish the remaining work, then check once more."

exit 0
