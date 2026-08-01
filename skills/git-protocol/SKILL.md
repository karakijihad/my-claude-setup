---
name: git-protocol
description: >
  Branching strategy, conventional commit format, safety rules, and PR/merge process.
  Use before creating a branch, staging, committing, pushing, merging, rebasing,
  cherry-picking, force-pushing, opening a PR, or any other git interaction.
---

# Git Workflow Protocol

> Applies to all projects using git version control.

**Core principle: every change is traceable, reversible, and isolated until verified.**

---

## 1. Branching Strategy

- **Always branch for multi-file changes.** Never commit directly to main/master for anything beyond a trivial single-file fix.
- **Branch naming:** `type/short-description` — e.g., `feat/user-auth`, `fix/login-redirect`, `refactor/db-queries`.
- **One concern per branch.** Don't mix a feature addition with an unrelated refactor. If you discover a separate issue while working, note it — don't fix it in the same branch.
- **Delete branches after merging.** Clean up stale branches. A merged branch has no further purpose.

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

- **Never force-push** to shared branches. If you need to rewrite history, do it on your own feature branch before sharing.
- **Never rewrite shared history.** Rebasing a branch that others have pulled from is destructive.
- **Never commit secrets.** The `check-secrets.sh` hook scans the staged diff for value-shaped secrets (`key = "value"` patterns, AWS keys, private-key blocks), but it's pattern-based — verify manually: no API keys, tokens, passwords, connection strings, or private keys in any committed file. If a secret was ever committed, rotate it immediately — git history is permanent.
- **Never commit generated files** unless explicitly required (e.g., lock files). Add build artifacts, node_modules, .env, and similar to `.gitignore`.

---

## 4. Pre-Commit Checklist

Before every commit:

- [ ] All tests passing
- [ ] Lint/format clean (hooks should handle this automatically)
- [ ] No secrets in the diff — check with `git diff --staged | grep -iE 'api_key|secret|token|password'`
- [ ] Commit message follows conventional format
- [ ] Changes are scoped to one logical unit

---

## 5. PR / Merge Protocol

- **Every PR needs a description** — what changed, why, how to test it.
- **Request review** for changes touching auth, data access, or security. Use `feature-dev:code-reviewer` for automated first-pass.
- **Squash merge** feature branches to keep main history clean. Preserve individual commits only when the intermediate steps have standalone value.
- **Don't merge with failing tests.** The pre-commit `run-tests.sh` hook enforces this locally, but verify.

---

_This skill is the single source of truth for git workflow. Where the resident session rules are terser, this skill wins._
