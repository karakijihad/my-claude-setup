---
name: project-docs
description: >
  The per-project Docs/ convention — decision records, audit evidence, and in-flight plans,
  with line budgets. Use when recording why a decision was made, when writing down what an
  audit found and how it was adjudicated, when opening or updating a plan file, when
  bootstrapping a new project's Docs folder, or when deciding whether a Docs tree is
  committed or kept local.
---

# Per-Project Docs

**Write down what git cannot reconstruct. Nothing else.** Git records what changed, when,
by whom, in what order. Documentation restating it is written once, read many times, stale
within a month, and misleading once stale.

```
Docs/
├── Decisions/YYYY-MM-DD.md     why, and what was rejected
├── Audit/claude|codex/DATE/    the adjudication, and what the auditor reported
├── Plan/<topic>/INDEX.md       + phase-N-<slug>.md — in-flight only
├── Plan/BACKLOG.md             identified, not yet planned
└── CODEMAP.md                  optional, for a repo too large to hold in one head
CHANGELOG.md                    at the repo root, committed, release-facing
```

- **`Decisions/`** — the decision, the constraint that forced it, and *the option you
  rejected*. A diff shows the road taken; nothing shows the road refused, and that is what
  gets re-litigated six months later.
- **`Audit/`** — findings **plus** adjudication. The refutations are the point: a commit
  never shows which findings were argued down and why. **An audit is not a decision.**
- **`Plan/`** — the only forward-looking tree. **Delete a plan when its work lands**, never
  `Plan/archive/`: a plan kept past its work reads as live to the next session.
- **`CODEMAP.md`** — permitted on two conditions: **roles, not histories**, and a **named
  regeneration trigger** in the file. A budget keeps a map short; only a trigger keeps it
  true.

**A project that must deviate says so in its own `CLAUDE.md`** — loaded every session. A
folder of overrides is loaded by nobody.

## Plan documents

The names are normative: `budget.sh` keys its table on them and cannot tell an index from a
phase by reading it. Work small enough to need no index stays one file,
`Plan/YYYY-MM-DD-<topic>.md`. When to write a plan at all, and how to execute one:
`planning-protocol`.

| File | Owns | Must not own |
|-|-|-|
| `INDEX.md` | resumption header · phase table with status, evidence ref, what each still owes · locked decisions as one-liners | narrative history, a "what landed" or "session history" section, phase detail |
| `phase-N.md` | current scope, exit criteria, rollback | superseded scope, backlog, anything another phase owns |
| `BACKLOG.md` | open items, five lines each: what · why deferred · the trigger · one ref | a `Closed` section, a `History` section |

**An index over budget is carrying a chronicle**, not prose needing compression — git holds
what changed, the table holds what is owed. **A phase over budget is a phase too large**:
split it, where each half has its own exit criterion. **A backlog entry that lands is
deleted in the pass that lands it.**

**Superseded scope is deleted, and one line survives** in the index's locked decisions. Not
struck through, not under an "original ruling" heading — that is how a 200-line phase
becomes a 1,200-line one. True whether or not `Docs/` is committed: where it is ignored the
text is gone, and where it is committed nobody greps `git log` for a ruling they don't know
exists.

## Sizing

**Line budgets live in each template's header** — the single source of truth, so the
numbers appear nowhere else. `budget.sh` warns after each write: once on crossing, again
only when an edit worsens the overage. It never blocks, and it is a backstop — a header is
read when someone opens the template and never again.

- **Decision entry** — decision · why, with the triggering incident · rejected alternative
  and what ruled it out · mechanism as file and function, not code. 1–2 sentences each.
- **Changelog entry** — `Added/Changed/Fixed/Removed`, one line per item. No narrative.

**Reject:** commit messages pasted verbatim, whole audit findings inlined, a paragraph per
file touched, line-count bookkeeping that rots — and the three worst, all the same mistake
of a document narrating its own past: a "session history" section, superseded text kept
struck through, closed items archived in place.

## Local by default

**`Docs/` is gitignored** — the whole tree, including subfolders that don't exist yet:

```gitignore
# Project docs — local by default, whole tree including subfolders added later
/Docs/
```

It holds working evidence, not a deliverable, and some of it is private. Three things
before adding the line:

- **It does not untrack anything.** Files already committed stay tracked. `git ls-files --
  Docs` tells you; `git rm --cached -r -- Docs/` is the fix and it **deletes them from the
  remote on the next push**. Never run it unprompted.
- **It is not a privacy remediation.** Anything pushed is in history and every clone.
- **On Windows and macOS it also matches `docs/`** — `core.ignorecase=true` is the default
  and anchoring does not help. That is where published doc sites live. Check with
  `git check-ignore -v docs/<file>`; on a collision the site wins.

In a monorepo, one anchored line per package (`/packages/foo/Docs/`).

**Committing `Docs/` is a legitimate choice — it just has to be written down**, in the
project's `CLAUDE.md`, or the next session helpfully re-adds the rule:

```md
## Docs policy

`Docs/` is versioned in this repo on purpose. Do not add `/Docs/` to `.gitignore`.
```

## Templates

In `${CLAUDE_PLUGIN_ROOT}/assets/templates/`:

| Template | Destination |
|-|-|
| `project-CLAUDE.md` | `<project>/CLAUDE.md` |
| `decision-entry.md` | `Docs/Decisions/YYYY-MM-DD.md` |
| `plan-index.md` | `Docs/Plan/<topic>/INDEX.md` |
| `plan-phase.md` | `Docs/Plan/<topic>/phase-N-<slug>.md` |
| `backlog.md` | `Docs/Plan/BACKLOG.md` |
| `codemap.md` | `Docs/CODEMAP.md` |
| `changelog-entry.md` | `<project>/CHANGELOG.md` |
| `Docs-skeleton/` | `<project>/Docs/` — copy wholesale |

`/setup` places `project-CLAUDE.md` and `Docs-skeleton/`, and offers `changelog-entry.md`
when the repo has none. The plan, backlog and code-map templates are written on first use —
there is nothing to plan on an empty repo, and unfilled boilerplate is the first thing to go
stale.

**Already have `Doclog/`?** Same tree, older name. Keep it. New projects get `Decisions/`.
