---
name: project-docs
description: >
  Use when a session is running long with work unfinished or is resuming one that was, when
  recording why a decision was made, when writing down what an audit found and how it was
  adjudicated, when bootstrapping a project's Docs tree, or when deciding whether that tree
  is committed or kept local.
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
├── Handoff/DATE/<slug>.md      where the work stood; you pass its path on
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
- **`Handoff/`** — one per piece of work, deleted when that work lands. Nothing reads one
  automatically; you hand its path to the next session. See §Handoff.
- **`CODEMAP.md`** — permitted on two conditions: **roles, not histories**, and a **named
  regeneration trigger** in the file. A budget keeps a map short; only a trigger keeps it
  true.

**A project that must deviate says so in its own `CLAUDE.md`** — loaded every session. A
folder of overrides is loaded by nobody. Same destination for a correction that recurs: once
is a one-off and belongs in memory, twice is a rule and belongs in `CLAUDE.md`.

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

## Handoff

**Watch your own context.** A `[context]` line arrives injected each 5%-of-window
crossing, carrying the status line's own fill and a handoff budget.

Short of that budget it is still a judgement against the objective, not a threshold to wait
for. Past it, write the handoff — the injection now says so. Keep your own
context low and cut noise as you go — delegate reads and runs, keep conclusions. Then ask,
at each natural break: does what the objective still needs fit cleanly in what is left, or
is this session now carrying enough stale output, dead ends and spent detail that a fresh
one, starting from a handoff, would do the rest better? When it is the second — or what is
left will not carry the work to a reviewable end — **write the handoff, give the operator its
path, and say to start a new session.** One line, then stop.

> Handoff written to `Docs/Handoff/2026-09-11/auth-migration.md` — start a new session and
> paste that path.

Deciding late is the only way to get this wrong. Once a compaction lands, the detail worth
writing down is the detail that is gone; too early costs minutes, too late cannot be done.

You cannot do the rest yourself. `/compact` is not available to the model, assistant text is
not submitted to the command parser, and no hook output or SDK call resets a conversation —
so don't spawn `claude -p` to fake it, that is a headless process whose work lands nowhere
the operator is looking. Nothing reads a handoff automatically either, and that is
deliberate: guessing which of several belongs to this session reinstates finished work as
live, while the operator naming a path answers it for free.

Write one also when the operator says to stop, when a phase lands with more to go, and when
handing work to another person.

**Resuming from one:** reconcile it against the repo before acting — `git status`, the suite,
the plan file. Where they disagree the repo is right; a handoff is what the last session
believed, not what is true. Say in one line where the work actually stands, then continue from
its `Next:` — a handoff exists so the new session picks the work up, not so it reports on it.
Load whatever `Review rung` and plan it names before the first edit.

**Shape:** `assets/templates/handoff.md`, at `Docs/Handoff/<YYYY-MM-DD>/<slug>.md`. The
folder is normative because `budget.sh` keys on it; the slug names the work, so three of them
can be told apart at a glance. Labelled lines and bullets, 45 lines, no headings — a handoff
is read at a glance or it is not read. Omit no field; an empty one is information.

- **Every `Done` line names what proves it.** "Added tests" is not an entry; "added four
  notification tests, 40 pass" is. The next session cannot re-derive what you verified — and
  **say what you did *not* do**, which is usually the line that stops it assuming the obvious
  next step already happened.
- **`Review rung` is not optional.** Without it a resumed session either re-reviews finished
  work or commits work that never had its Tier-2 pass, and the second one is silent.

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
| `handoff.md` | `Docs/Handoff/<YYYY-MM-DD>/<slug>.md` |
| `Docs-skeleton/` | `<project>/Docs/` — copy wholesale |

`/setup` places `project-CLAUDE.md` and `Docs-skeleton/`, and offers `changelog-entry.md`
when the repo has none. The plan, backlog and code-map templates are written on first use —
there is nothing to plan on an empty repo, and unfilled boilerplate is the first thing to go
stale.

**Already have `Doclog/`?** Same tree, older name. Keep it. New projects get `Decisions/`.
