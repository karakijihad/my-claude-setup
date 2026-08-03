---
name: project-docs
description: >
  The per-project Docs/ convention — session notes, changelog, doclog decision records,
  audit folders, CODEMAP — with line budgets and templates. Use when writing a session
  note, changelog entry, or architecture decision record, when recording what an audit
  found, when updating CODEMAP after a structural change, or when bootstrapping a new
  project's Docs folder.
---

# Per-Project Docs

**Newest first in every append-only file. Dated files are one per day. Folder-based to prevent bloat.**

```
Docs/
├── Changelog/
│   ├── README.md              # Index: version bumps, links by date
│   └── YYYY-MM-DD.md          # One file per day
├── Doclog/
│   ├── README.md              # Index: decision titles by date
│   └── YYYY-MM-DD.md          # One file per day
├── Sessions/
│   └── YYYY-MM-DD.md          # One file per day — work log
├── Audit/
│   ├── README.md              # How audits are produced and reconciled
│   ├── claude/YYYY-MM-DD/audit-{N}.md   # the adjudication
│   └── codex/YYYY-MM-DD/audit-{N}.md    # what the auditor reported
├── Plan/                      # Stage checklists for in-flight work
├── Logs/
│   ├── CODEMAP.md             # File map — roles, data flows
│   └── …                      # Build logs, benchmarks
└── Protocols/                 # Project-specific overrides only (rare)
```

## What is authoritative

**Decisions that were accepted** live in `Doclog/` and `Sessions/`. **What reviewers found**
lives in `Audit/`. An audit is never a decision by itself.

`trio:trio-audit` produces both halves of that tree — `codex/` is what its lenses reported,
`claude/` is the verdict per finding — and promoting a finished run is what fills them. Record
the same two halves by hand when the audit was manual; what matters is that the refutations
survive, since a commit shows what changed, not which findings were argued down.

`CODEMAP.md` updates after any structural change — files created, deleted, moved, restructured.

## Sizing — highlights, not monoliths

These files exist for *trackability*, not reconstruction. Evidence lives in commits, diffs,
audits, and plan folders; docs link to it rather than duplicating it.

- **Line budgets live in each template's header** — that header is the single source of truth,
  so don't restate the numbers anywhere else.
- **Session note** — one-line headline plus 3–5 bullets per workstream: what changed, why,
  where the evidence lives. Link audits and plan files; don't inline their prose.
- **Changelog entry** — `Added/Changed/Fixed/Removed` lists, one line per item with a file path.
  No paragraphs, no narrative, no "review process" sections.
- **Doclog entry** — Decision (1–2 sentences) · Why (1–2 sentences, including the triggering
  incident) · Mechanism (1–2 sentences, file and function, not code). Longer than that means it
  belongs in a plan or audit, linked.
- **CODEMAP** — structural map only. Roles, not histories.

**Reject these:** pasting commit messages verbatim, embedding whole audit findings, a paragraph
per file touched, restating the same change under Done *and* Files Changed *and* Commits, and
line-count bookkeeping that rots.

If a reader needs the full story they open the commit, the audit, or the plan file. The daily
doc's job is to help them find it.

## Session note sections

`Done · Decisions · Security Review · Files Changed · Commits · Next · Corrections → Protocol Updates`

Write it before committing.

## Templates

In `${CLAUDE_PLUGIN_ROOT}/assets/templates/`:

| Template | Destination |
|-|-|
| `project-CLAUDE.md` | `<project>/CLAUDE.md` |
| `session-note.md` | `Docs/Sessions/YYYY-MM-DD.md` |
| `doclog-entry.md` | `Docs/Doclog/YYYY-MM-DD.md` |
| `changelog-entry.md` | `Docs/Changelog/YYYY-MM-DD.md` |
| `Docs-skeleton/` | `<project>/Docs/` — copy wholesale, includes `Audit/README.md` |

`/bootstrap-project` places all of these for you.
