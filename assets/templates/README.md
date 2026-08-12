# Templates

Copy these into a new project to bootstrap the conventions described in the `project-docs` skill.

| Template | Destination | Purpose |
|-|-|-|
| `project-CLAUDE.md` | `<project>/CLAUDE.md` | Per-project CLAUDE.md skeleton |
| `decision-entry.md` | `Docs/Decisions/YYYY-MM-DD.md` | Decision record — why, and what was rejected |
| `changelog-entry.md` | `<project>/CHANGELOG.md` | Release-facing changelog, grouped by version |
| `Docs-skeleton/` | `<project>/Docs/` | Folder tree — copy wholesale. Includes `Audit/README.md`, which explains how audits are produced and reconciled |

## Set up a new project

From the project root, run `/setup`. It places `CLAUDE.md` and the `Docs/` tree,
fills in what it can read from the repo, and tells you what still needs your input. Edit
`Docs/Audit/README.md` only if the project needs its own audit conventions.

## Rules

- **Only what git cannot reconstruct.** It already has what changed and when.
- **Newest first** in every append-only doc. One file per day for `Decisions/`.
- **Record the rejected option**, not just the accepted one.
- **Audit is evidence, not decision.** Decisions belong in `Decisions/`.
- **The changelog lives at the repo root** and is committed — it's for people without your
  working copy.
