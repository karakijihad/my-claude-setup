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
| `.gitignore` | Covers `.env*`; whether `/Docs/` is ignored; whether `git ls-files -- Docs` shows tracked files; whether a `Docs policy` section in `CLAUDE.md` opts out |
| `.env.example` | Exists if the project reads env vars — `security-protocol` §04 requires it |
| CI | Any of `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `azure-pipelines.yml`, `.circleci/config.yml`, `.travis.yml`, `bitbucket-pipelines.yml`, `appveyor.yml`, `.buildkite/`; and whether `CLAUDE.md` has a `## CI` section recording it |
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
- **Missing `Docs/` trees** → add only the missing ones from `Docs-skeleton/`. Three is the
  whole convention; don't add a fourth folder because the repo happens to have one.
- **`Docs/` not ignored** → it is local by default (see `project-docs`). This is the one check
  that is a *decision point*, not a gap, so present it as a choice and let the user pick:
  - **Keep it versioned** → change nothing, and append a `Docs policy` section to `CLAUDE.md`
    saying so. Without that, the next session re-adds the line.
  - **Local from here on** → append `/Docs/` to `.gitignore`. Anchored — bare `Docs/` also
    catches nested `packages/*/Docs/`. If the repo has a lowercase `docs/`, check
    `git check-ignore -v docs/<file>` afterwards: `core.ignorecase=true` is the default on
    Windows and macOS, so the pattern matches `docs/` too, anchor or no anchor. A published
    docs site wins that collision.
  - **Files already tracked under `Docs/`** → say plainly that the ignore line alone changes
    nothing for them, that `git rm --cached -r -- Docs/` is what untracks them, and that its
    next push **removes them from the remote**. Run it only on an explicit yes. And if the
    worry is that something private was already pushed: this is not a remediation. It is in
    history and in every clone — that needs rotation and a deliberate history rewrite, which is
    outside this command.
- **`Logs/` or `Protocols/`** → leave them exactly as they are, and don't recreate them
  elsewhere. `Protocols/` in particular was dropped because nothing ever loaded it: a project
  deviation belongs in that project's `CLAUDE.md`, which *is* loaded. If the folder holds real
  content, say so and offer to move it into `CLAUDE.md` — don't delete someone's writing.
- **`Doclog/`** → leave the folder name alone. It is the same tree as `Decisions/` under the
  older name, and renaming an append-only history buys nothing. Say it's recognised and move on.
- **`Sessions/`** → don't delete it. Report how many files it holds and say that the convention
  dropped it because `git log` covers the same ground. Removing it is the user's call.
- **`Docs/Changelog/`** → offer to consolidate into a root `CHANGELOG.md` grouped by release,
  using `changelog-entry.md`. Keep the originals until the user confirms the merge reads right.
- **CI** → found but unrecorded: propose a `## CI` section (provider, trigger, the commands it
  runs, the check command) and let the user accept it, per the rule above. None found: ask once
  whether the project wants CI and record either answer — `none, confirmed <today>` stops the
  re-ask. Never write a workflow file here.
- **Stale plan files** → list them, propose deletion, delete nothing unprompted.

## 4. Report what changed

Files created, files appended to, and anything you deliberately left alone with the reason.
If the repo was already compliant, say exactly that in one line rather than inventing work.

**Never** commit, and never touch `.git/`, `.env`, or a lockfile. This command writes project
docs. Nothing else.
