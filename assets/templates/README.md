# Templates

Copy these into a new project to bootstrap the conventions described in the `project-docs` skill.

| Template | Destination | Purpose |
|-|-|-|
| `project-CLAUDE.md` | `<project>/CLAUDE.md` | Per-project CLAUDE.md skeleton |
| `session-note.md` | `Docs/Sessions/YYYY-MM-DD.md` | Daily work log |
| `doclog-entry.md` | `Docs/Doclog/YYYY-MM-DD.md` | Architecture decision record (one file per day) |
| `changelog-entry.md` | `Docs/Changelog/YYYY-MM-DD.md` | Daily changelog file |
| `Docs-skeleton/` | `<project>/Docs/` | Full folder tree — copy wholesale. Includes `Audit/README.md`, which explains how audits are produced and reconciled |

## Bootstrap a new project

From the project root, run `/bootstrap-project`. It places `CLAUDE.md` and the `Docs/` tree,
fills in what it can read from the repo, and tells you what still needs your input. Edit
`Docs/Audit/README.md` only if the project needs its own audit conventions.

## Rules

- **Newest first** in every append-only doc.
- **One file per day** for Sessions, Doclog, and Changelog.
- **Audit is evidence, not decision.** Decisions belong in Doclog or Sessions.
- **Update CODEMAP** after any structural change.
