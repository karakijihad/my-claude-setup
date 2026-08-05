---
name: project-docs
description: >
  The per-project Docs/ convention — decision records, audit evidence, and in-flight plans,
  with line budgets and templates. Use when recording why a decision was made, when writing
  down what an audit found and how it was adjudicated, when opening or updating a plan file,
  or when bootstrapping a new project's Docs folder.
---

# Per-Project Docs

**Write down what git cannot reconstruct. Nothing else.**

Git already records what changed, when, by whom, and in what order. Documentation that
restates it is pure cost: written once, read many times, stale within a month, and
misleading once stale. Three things survive that test.

```
Docs/
├── Decisions/YYYY-MM-DD.md     why, and what was rejected
├── Audit/
│   ├── claude/YYYY-MM-DD/      the adjudication — verdict per finding
│   └── codex/YYYY-MM-DD/       what the auditor reported
└── Plan/                       in-flight only; delete when the work lands
CHANGELOG.md                    at the repo root, committed, release-facing
```

## Why these three

- **`Decisions/`** — the accepted decision, the constraint that forced it, and *the option
  you rejected*. A diff shows the road taken; nothing in git shows the road refused, and
  that is the thing you re-litigate six months later.
- **`Audit/`** — findings **plus** adjudication. The refutations are the point: a commit
  shows what changed, never which findings were argued down and why. `trio:trio-audit`
  fills both halves — `codex/` is what its lenses reported, `claude/` the verdict per
  finding. Record both by hand when the audit was manual. **An audit is never a decision
  by itself.**
- **`Plan/`** — the only forward-looking tree. It exists so work survives a context reset;
  see `planning-protocol` for its structure. Delete a plan when its work lands — a
  completed plan is history, and git holds history.

**`CHANGELOG.md` lives at the repo root and is committed.** A changelog exists to be read
by people who don't have your working copy, so a dated file inside a possibly-gitignored
`Docs/` cannot do that job. Group by release, not by day.

## What was removed, and why

`Sessions/` and `Docs/Changelog/` are gone. A daily "what I did" log is `git log
--since=yesterday` with worse fidelity. If a session produced something worth keeping it was
a *decision* — write it in `Decisions/`, including the dead ends, so nobody re-walks them.

Two trees are still available, just not scaffolded by default — create them only on the day
you actually need one:

- **`Docs/Protocols/`** — project-specific overrides of a protocol skill. Rare, and real:
  use it when a project genuinely must deviate, and say which protocol it overrides.
- **`Docs/Logs/CODEMAP.md`** — a structural file map. Generate it on demand rather than
  maintaining it; a CODEMAP that lags a rename is worse than none, because it is believed.

## Sizing — highlights, not monoliths

These files exist for *trackability*, not reconstruction. Evidence lives in commits, diffs,
and audits; docs link to it rather than duplicating it.

- **Line budgets live in each template's header** — that header is the single source of
  truth, so don't restate the numbers anywhere else.
- **Decision entry** — Decision (1–2 sentences) · Why, including the triggering incident
  (1–2) · Rejected alternative and what ruled it out (1–2) · Mechanism, file and function
  rather than code (1–2). Longer than that belongs in a plan or audit, linked.
- **Changelog entry** — `Added/Changed/Fixed/Removed`, one line per item. No narrative.

**Reject these:** pasting commit messages verbatim, embedding whole audit findings, a
paragraph per file touched, restating a change under three headings, and line-count
bookkeeping that rots.

If a reader needs the full story they open the commit, the audit, or the plan. These files
exist to help them find it.

## Templates

In `${CLAUDE_PLUGIN_ROOT}/assets/templates/`:

| Template | Destination |
|-|-|
| `project-CLAUDE.md` | `<project>/CLAUDE.md` |
| `decision-entry.md` | `Docs/Decisions/YYYY-MM-DD.md` |
| `changelog-entry.md` | `<project>/CHANGELOG.md` |
| `Docs-skeleton/` | `<project>/Docs/` — copy wholesale, includes `Audit/README.md` |

`/bootstrap-project` places all of these for you.

**Already have `Doclog/`?** It's the same tree under the older name. Keep it — renaming an
append-only history buys nothing. New projects get `Decisions/`.
