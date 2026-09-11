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
├── HANDOFF.md                  where the work stood — one file, overwritten
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
- **`HANDOFF.md`** — one file, overwritten, deleted when the work lands. A second one means
  the next session reads the wrong one. See §Handoff.
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

**Read your own context, then decide.** Where the harness gives you a context-usage figure,
use it — but it is not the number in the operator's status line. That one is computed from
the last API response and handed to the status-line subprocess, which does not feed it back
to you; the two measure the same window at different moments and by different accounting, so
never quote one as the other. If you have no figure at all, fall back on the triggers below
rather than inventing a percentage.

Before starting anything substantial, compare what remains against what the work needs — and
say which way you went, in one line:

- **Continue here** — the remaining work fits, with room left for the verify and the review.
- **Hand off** — it doesn't. Write `Docs/HANDOFF.md`, then stop and ask for `/clear`.

**The flow is three automatic steps and one keystroke.** You write the handoff, the user
types `/clear`, `SessionStart` fires with source `clear`, and the hook tells the fresh session
a handoff exists and how old it is — then **asks before loading it**, because `/clear` is also
just how a fresh start is made and the file on disk may be finished or a week stale. After a
compaction or a resume it loads without asking: those are not chosen, and the handoff is the
work that was interrupted. You cannot do the clearing part:
no tool, hook field or SDK call lets a session clear itself — it destroys the user's
conversation, so it stays theirs. So end the turn by naming the file and asking for the
clear, in one line. Don't spawn `claude -p` to fake it: that is a separate headless process
whose work lands nowhere the user is looking.

**This is your call, not a question for the user** — but state it so they can overrule it.
Deciding late is the only way to get it wrong: once a compaction lands, the detail you would
have written down is the detail that is gone. Too early costs minutes; too late cannot be
done at all.

Write one also when the user says to stop, when a phase lands with more to go, and when
handing work to another session or another person.

**Shape:** `assets/templates/handoff.md`. Labelled lines and bullets, 45 lines, no headings —
a handoff is read at a glance or it is not read. Omit no field; an empty one is information.

- **`Written:` is a real date, not a guess.** It is what the /clear branch reports the
  handoff’s age from; without it the age falls back to the file timestamp, which a copy or a
  restore resets, so a fortnight-old handoff can read as minutes old.
- **Every `Done` line names what proves it.** "Added tests" is not an entry; "added four
  notification tests, 40 pass" is. The next session cannot re-derive what you verified — and
  **say what you did *not* do**, which is usually the line that stops it assuming the obvious
  next step already happened.
- **`Review rung` is not optional.** Without it a resumed session either re-reviews finished
  work or commits work that never had its Tier-2 pass, and the second one is silent.
- **The repo outranks the handoff.** On resumption, reconcile against `git status`, the suite
  and the plan file before acting. A handoff is what the last session believed.

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
| `handoff.md` | `Docs/HANDOFF.md` |
| `Docs-skeleton/` | `<project>/Docs/` — copy wholesale |

`/setup` places `project-CLAUDE.md` and `Docs-skeleton/`, and offers `changelog-entry.md`
when the repo has none. The plan, backlog and code-map templates are written on first use —
there is nothing to plan on an empty repo, and unfilled boilerplate is the first thing to go
stale.

**Already have `Doclog/`?** Same tree, older name. Keep it. New projects get `Decisions/`.
