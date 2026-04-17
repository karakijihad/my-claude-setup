# Project Template

Templates have moved to [`.claude/Templates/`](./.claude/Templates/). See that directory for:

- `project-CLAUDE.md` — per-project CLAUDE.md skeleton
- `session-note.md` — daily session log
- `doclog-entry.md` — architecture decision record (one file per day)
- `changelog-year.md` — yearly changelog
- `audit-README.md` — audit folder usage
- `Docs-skeleton/` — full `Docs/` folder tree to copy into new projects

## Bootstrap

```bash
cd your-project
cp ~/.claude/Templates/project-CLAUDE.md ./CLAUDE.md
cp -r ~/.claude/Templates/Docs-skeleton ./Docs
```

Then fill in project specifics in `CLAUDE.md`. The global `~/.claude/CLAUDE.md` handles protocols, tools, and workflow — your project file only needs architecture, key files, tech stack, commands, environment, and gotchas.
