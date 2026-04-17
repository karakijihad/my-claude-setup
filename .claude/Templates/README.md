# Templates

Copy these into a new project to bootstrap the conventions described in `~/.claude/CLAUDE.md` → Per-Project Docs.

| Template | Destination | Purpose |
|-|-|-|
| `project-CLAUDE.md` | `<project>/CLAUDE.md` | Per-project CLAUDE.md skeleton |
| `session-note.md` | `Docs/Sessions/YYYY-MM-DD.md` | Daily work log |
| `doclog-entry.md` | `Docs/Doclog/YYYY-MM-DD.md` | Architecture decision record (one file per day) |
| `changelog-entry.md` | `Docs/Changelog/YYYY-MM-DD.md` | Daily changelog file |
| `audit-README.md` | `Docs/Audit/README.md` | How audits are produced and reconciled |
| `Docs-skeleton/` | `<project>/Docs/` | Full folder tree — copy wholesale |

## Bootstrap a new project

```bash
cd your-project
cp ~/.claude/Templates/project-CLAUDE.md ./CLAUDE.md
cp -r ~/.claude/Templates/Docs-skeleton ./Docs
# Edit CLAUDE.md to fill in project specifics.
# Edit Docs/Audit/README.md only if you need project-specific overrides.
```

## Rules (from CLAUDE.md)

- **Newest first** in every append-only doc.
- **One file per day** for Sessions, Doclog, and Changelog.
- **Audit is evidence, not decision.** Decisions belong in Doclog or Sessions.
- **Update CODEMAP** after any structural change.
