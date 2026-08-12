---
name: git-protocol
description: >
  Branching strategy, conventional commit format, safety rules, the post-push CI check, and
  PR/merge process. Use before creating a branch, staging, committing, pushing, merging,
  rebasing, cherry-picking, force-pushing, opening a PR, or any other git interaction.
---

# Git Workflow Protocol

> Applies to all projects using git version control.

**Core principle: every change is traceable, reversible, and isolated until verified.**

---

## 1. Branching Strategy

- **Ask before creating a branch. Never create one unprompted.** Branching is the user's call, not a default to apply because a change touched several files. Most repos here are single-maintainer, where a branch and a PR to yourself is pure ceremony: it splits the history, leaves a second branch to clean up, and delays the work landing for no review that was ever going to happen.
- **Default: commit to the branch already checked out.** Usually `main`. Size is not the trigger — a 17-file change on a solo repo still belongs on `main`.
- **Ask when there is a real reason to isolate**, and say which reason: other people pull this branch and the work would break them; the change needs review before it lands; it is genuinely experimental and may be abandoned; or CI gates merges. If none of those hold, don't raise it.
- **Branch naming, when the user does want one:** `type/short-description` — e.g., `feat/user-auth`, `fix/login-redirect`.
- **One concern per branch.** If you discover a separate issue while working, note it — don't fix it in the same branch.
- **Delete branches after merging**, and confirm the merge landed. Use `git branch -d`, which refuses an unmerged branch; reach for `-D` only when the user has said to discard the work.

> This rule used to read "always branch for multi-file changes." On a repo with one
> committer it produces exactly the mess it was meant to prevent: a throwaway branch
> and a self-approved PR for a change no second person will ever review. Rules that
> manufacture ceremony get ignored, and an ignored rule is worse than no rule.

---

## 2. Commit Conventions

Use **conventional commits**: `type(scope): description`

**Types:**

| Type       | When                                          |
| ---------- | --------------------------------------------- |
| `feat`     | New functionality                             |
| `fix`      | Bug fix                                       |
| `refactor` | Code restructuring with no behavior change    |
| `test`     | Adding or modifying tests                     |
| `docs`     | Documentation only                            |
| `chore`    | Build, CI, tooling, dependencies              |
| `security` | Security-related changes (patches, hardening) |

**Rules:**

- One logical change per commit. If you can't describe it in one sentence, split it.
- Description is imperative mood: "add user auth" not "added user auth" or "adding user auth."
- Reference issue/ticket numbers when they exist: `fix(auth): handle expired tokens (#142)`
- Keep the subject line under 72 characters. Use the body for detail if needed.

---

## 3. Safety Rules

- **Ask before any decision that reshapes the repo, rather than picking one.** Creating a branch, opening a PR, merging, rebasing, tagging, deleting a branch, changing the default branch. These are the maintainer's calls and they are cheap to ask about — a one-line question costs far less than the cleanup when the guess is wrong. Committing and pushing the work you were asked to do is not in this list; do that.
- **Never force-push** to shared branches. If you need to rewrite history, do it on your own feature branch before sharing.
- **Never rewrite shared history.** Rebasing a branch that others have pulled from is destructive.
- **Never commit secrets.** The `guard.sh` hook scans the staged diff for value-shaped secrets (`key = "value"` patterns, AWS keys, private-key blocks), but it's pattern-based — verify manually: no API keys, tokens, passwords, connection strings, or private keys in any committed file. If a secret was ever committed, rotate it immediately — git history is permanent.
- **Never commit generated files** unless explicitly required (e.g., lock files). Add build artifacts, node_modules, .env, and similar to `.gitignore`.

---

## 4. Pre-Commit Checklist

Before every commit:

- [ ] All tests passing
- [ ] Lint/format clean — **run the project's own command**; no hook does this for you
- [ ] If the repo has CI, **run what it runs** — its steps are often stricter than the local
      defaults, and one command here saves a red run and a follow-up commit
- [ ] No secrets in the diff — check with `git diff --staged | grep -iE 'api_key|secret|token|password'`
- [ ] Commit message follows conventional format
- [ ] Changes are scoped to one logical unit

---

## 5. PR / Merge Protocol

- **Every PR needs a description** — what changed, why, how to test it.
- **Request review** for changes touching auth, data access, or security. Use `feature-dev:code-reviewer` for automated first-pass.
- **Squash merge** feature branches to keep main history clean. Preserve individual commits only when the intermediate steps have standalone value.
- **Don't merge with failing tests.** Nothing enforces this locally — the pre-commit test-runner hook was removed for cost. Run the suite yourself and read the output before merging.

---

## 6. After the Push

**No CI in the repo → nothing to do here.** `post-push.sh` stays silent and so should you;
setting one up is `/setup`'s question or the user's request, not a mid-task suggestion.

With CI: match the run by **commit SHA, never the branch** — a push returns before its run is
created, so a branch query answers with the previous commit's run, often green. Report one of
green / red / cancelled / skipped / queued / unavailable; only green passes. Don't poll — finish
the remaining work and check once more. Record the repo's CI once in its `CLAUDE.md` under `## CI`.

---

_This skill is the single source of truth for git workflow. Where the resident session rules are terser, this skill wins._
