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
   Never scaffold `Logs/` or `Protocols/` — they're created on the day they're needed.
4. Fill in the parts of `./CLAUDE.md` you can determine by reading the repo: project name and
   one-line purpose, tech stack, the real commands from `package.json` / `pyproject.toml` /
   `Makefile`, and key directories. Leave `Gotchas` for the user — you can't know those yet.
5. Report what you created and what still needs the user's input.

The global protocols cover security, testing, git, delegation, and context. The project file
should carry only what is specific to this repo: architecture, key files, stack, commands,
environment, and gotchas.
