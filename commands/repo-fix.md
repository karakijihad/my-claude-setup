---
description: Survey an existing repo against this plugin's conventions and offer to fix the gaps
---

Bring an **existing** repo up to the conventions in `project-docs`. `/bootstrap-project` assumes
a blank slate and writes the tree; this one assumes history, so it **surveys first and changes
nothing until you agree**. Use it on a repo you've been working in for a while, or one that
still follows the older seven-folder layout.

## 1. Survey — read-only, no writes in this step

Check each of these against the current directory. Report what you find, not what you assume.

| Check | Looking for |
|-|-|
| `CLAUDE.md` | Present at the root? Does it cover project purpose, stack, key files, commands, gotchas? |
| `Docs/` | Which of `Decisions/ Audit/ Plan/` exist |
| Old layout | `Doclog/`, `Sessions/`, `Docs/Changelog/`, `Logs/`, `Protocols/` |
| `CHANGELOG.md` | At the **repo root**, committed |
| `.gitignore` | Covers `.env*`, and whether `Docs/` is deliberately ignored |
| `.env.example` | Exists if the project reads env vars — `security-protocol` §04 requires it |
| Stale plans | Anything in `Docs/Plan/` whose work already landed |

## 2. Report

One table: **finding · proposed action · risk**. Then stop and ask. Do not batch the writes
with the survey — the point of this command is that you see the list before anything moves.

## 3. Apply what was agreed

- **Missing `CLAUDE.md`** → copy `${CLAUDE_PLUGIN_ROOT}/assets/templates/project-CLAUDE.md`,
  then fill in what you can read from the repo: name and one-line purpose, stack, the real
  commands from `package.json` / `pyproject.toml` / `Makefile`, key directories. Leave
  `Gotchas` for the user — you cannot know those.
- **Existing `CLAUDE.md`** → **never rewrite it.** Name the sections it lacks, show the exact
  text you'd append, and let the user accept per section. A project's instructions are theirs.
- **Missing `Docs/` trees** → add only the missing ones from `Docs-skeleton/`. Never scaffold
  `Logs/` or `Protocols/`; those are created the day they're needed.
- **`Doclog/`** → leave the folder name alone. It is the same tree as `Decisions/` under the
  older name, and renaming an append-only history buys nothing. Say it's recognised and move on.
- **`Sessions/`** → don't delete it. Report how many files it holds and say that the convention
  dropped it because `git log` covers the same ground. Removing it is the user's call.
- **`Docs/Changelog/`** → offer to consolidate into a root `CHANGELOG.md` grouped by release,
  using `changelog-entry.md`. Keep the originals until the user confirms the merge reads right.
- **Stale plan files** → list them, propose deletion, delete nothing unprompted.

## 4. Report what changed

Files created, files appended to, and anything you deliberately left alone with the reason.
If the repo was already compliant, say exactly that in one line rather than inventing work.

**Never** commit, and never touch `.git/`, `.env`, or a lockfile. This command writes project
docs. Nothing else.
