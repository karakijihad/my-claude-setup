---
description: Scaffold a project CLAUDE.md and the Docs/ convention into the current directory
---

Set up this project to follow the `project-docs` convention.

1. Confirm the working directory is the project root. If it looks wrong, ask before writing.
2. If `./CLAUDE.md` does not exist, copy `${CLAUDE_PLUGIN_ROOT}/assets/templates/project-CLAUDE.md`
   to `./CLAUDE.md`. If it does exist, leave it alone and say so — never overwrite a project's
   existing instructions.
3. If `./Docs/` does not exist, copy `${CLAUDE_PLUGIN_ROOT}/assets/templates/Docs-skeleton/` to
   `./Docs/`. If it exists, report which of `Decisions/ Audit/ Plan/` are missing and offer to
   add only those. A project already using the older `Doclog/` name keeps it — don't rename an
   append-only history, and don't create `Decisions/` alongside it.
   Then, if `./CHANGELOG.md` does not exist, offer to add it from `changelog-entry.md`.
   Those three are the whole convention — never invent a fourth folder. A project-specific
   deviation goes in that project's `CLAUDE.md`, which is loaded every session.
4. **Make `Docs/` local.** It is gitignored by default — the whole tree, including subfolders
   added later — because it holds working evidence, some of it private. In order:
   - If `./CLAUDE.md` already has a `Docs policy` section opting out, **stop here** and say so.
     That section exists precisely to stop a later session re-adding the line.
   - If the repo has a lowercase `docs/`, run `git check-ignore -v docs/<some-file>` after
     adding the line and check it didn't catch it. On Windows and macOS `core.ignorecase=true`
     is the default, so `/Docs/` matches `docs/` too — and anchoring does not prevent that. On a
     collision, the published `docs/` site wins: don't add the line, and record why in `CLAUDE.md`.
   - Otherwise append to `./.gitignore` (creating it if absent), then tell the user it's ignored
     and that saying so overrides it:
     ```gitignore
     # Project docs — local by default, whole tree including subfolders added later
     /Docs/
     ```
   Anchored, because bare `Docs/` also matches a nested `packages/*/Docs/`. This is a fresh-repo
   command, so nothing under `Docs/` should be tracked yet — if `git ls-files -- Docs` returns
   anything, you are in `/repo-fix` territory: report it and don't untrack anything here.
5. Fill in the parts of `./CLAUDE.md` you can determine by reading the repo: project name and
   one-line purpose, tech stack, the real commands from `package.json` / `pyproject.toml` /
   `Makefile`, and key directories. Leave `Gotchas` for the user — you can't know those yet.
6. Report what you created and what still needs the user's input.

The global protocols cover security, testing, git, delegation, and context. The project file
should carry only what is specific to this repo: architecture, key files, stack, commands,
environment, and gotchas.
