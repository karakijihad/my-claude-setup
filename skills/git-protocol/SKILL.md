---
name: git-protocol
description: >
  Use before branching, staging, committing, pushing, merging, rebasing, cherry-picking,
  force-pushing, or opening a PR.
---

# Git Workflow Protocol

Conventional commits, one logical change per commit, imperative subject under 72 characters.
That part is standard and not restated here. What follows is what this setup decides
differently, plus the rules that get skipped under pressure.

---

## 1. Don't branch unless asked

- **Ask before creating a branch. Never create one unprompted.** Most repos here are
  single-maintainer, where a branch and a PR to yourself is pure ceremony: it splits the
  history, leaves a second branch to clean up, and delays the work landing for a review that
  was never going to happen.
- **Default: commit to the branch already checked out.** Usually `main`. Size is not the
  trigger — a 17-file change on a solo repo still belongs on `main`.
- **Ask when there is a real reason to isolate, and name it:** others pull this branch and
  the work would break them; the change needs review before it lands; it is experimental and
  may be abandoned; or CI gates merges. If none hold, don't raise it.
- Naming, when the user does want one: `type/short-description`. One concern per branch.
  Delete it after the merge lands, with `git branch -d` — it refuses an unmerged branch, and
  `-D` is only for work the user has said to discard.

## 2. Ask before reshaping the repo

Creating a branch, opening a PR, merging, rebasing, tagging, deleting a branch, changing the
default branch. These are the maintainer's calls and cheap to ask about — a one-line question
costs far less than the cleanup when the guess is wrong.

**Committing and pushing the work you were asked to do is not in this list. Do that.**

## 3. Before every commit

- **No secrets in the diff.** `guard.sh` scans the staged diff for value-shaped secrets, but
  it is pattern-based — read the diff yourself. A secret that was ever committed must be
  rotated, not just removed: git history is permanent.
- If the repo has CI, run what CI runs — its steps are often stricter than the local
  defaults, and one command here saves a red run and a follow-up commit.

## 4. After the push

**No CI in the repo → nothing to do.** `post-push.sh` stays silent and so should you; setting
one up is `/setup`'s question or the user's request, not a mid-task suggestion.

With CI: match the run by **commit SHA, never the branch** — a push returns before its run is
created, so a branch query answers with the previous commit's run, often green. Report one of
green / red / cancelled / skipped / queued / unavailable; only green passes. Don't poll —
finish the remaining work and check once more.

**Record the repo's check command once in its `CLAUDE.md` under `## CI`.** `post-push.sh`
points there rather than guessing a provider from the files in the tree.
