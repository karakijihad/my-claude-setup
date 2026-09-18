---
name: planning-protocol
description: >
  Use before starting work that breaks into ordered phases, when a task won't fit one
  context window, when the user asks for a plan, roadmap, or phased breakdown, and when
  resuming work against an existing plan file in Docs/Plan/.
---

# Planning Protocol

Where a plan lives and its line budgets: `project-docs`. This skill covers when to write
one, what it may say, and how to execute it.

## 1. When to offer

Both must hold: the work breaks into **ordered phases** (N can't start until N-1 is done),
and it **won't fit one context window**. Either alone is not enough — a 20-file rename is
one phase; a 3-file change can be four.

**Four phases is the tripwire.** At four, offer unless you can name why it all fits one
window. Counting phases is checkable; predicting context is not, and "this will fit" is how
a plan doesn't get written — the cost landing on the session that resumes from a summary.

Don't offer when the work is under ~50 lines, is pure research, finishes in one commit, or
already has a plan file — extend that one.

## 2. The offer

Stop before the first edit. Name the phases in one sentence, then ask. No pitch.

> "This is four ordered phases — schema, migration, API, UI — and it won't fit one
> context. Plan file first, or straight in?"

Declined → proceed, no gate, no second mention. Re-offer **once**, only on a concrete
overrun: more phases than estimated, or one phase spills the context. A second decline is
final.

## 3. A plan is a guide, not a specification

This is the rule that keeps plan files worth reading. A phase says where the work stands and
what "done" looks like — it does not restate the code, and it does not explain the codebase
to a reader who has one.

- **Cite, don't copy.** `src/auth/token.ts:40-88`, not the function pasted in. The file is
  the source of truth and the plan goes stale the moment it disagrees.
- **A phase is a handful of lines.** Scope in, scope out, exit criteria, rollback. If a
  phase needs three paragraphs to state, it is two phases.
- **No inline implementation.** A plan that contains the diff has become a worse copy of
  the diff.
- **Nothing a reader could get from `git log`** — it holds the *plan*, not the history.

`budget.sh` warns when `INDEX.md` passes 100 lines or a `phase-*.md` passes 200. Treat the
first warning as the ceiling, not the target.

## 4. Drafting

`INDEX.md` opens with the resumption header — the reason the folder exists:

```markdown
Phase: 2 of 4 — migration · status: in-progress
Verified: phase 1 green — schema at `db/schema.sql:1-88`, migration test passing
Scouted: YYYY-MM-DD @ a1b2c3d — phase 2 re-checked, no drift
Next: backfill script, then the API cutover
Updated: YYYY-MM-DD
```

Directly under it, verbatim — a rule living only in this skill is one the resuming session
may never read. Keep it a pointer, never a copy of §5: a plan written months ago would carry a
stale mechanism and be believed.

```markdown
> Before starting any phase, scout it against the codebase first — brief and skip
> condition in `my-claude-setup:planning-protocol` §5. The plan is older than the code.
```

Each phase carries **scope in · scope out · exit criteria · rollback**. Scope-out is what
stops the plan growing. Exit criteria cite evidence — `file:line`, test output, a
screenshot path — never "it works". Rollback is written before you need it.

Status vocabulary is fixed: `not-started` · `in-progress` · `awaiting-review` · `green` ·
`blocked`. It lives in the header, not in prose.

**This overrides `superpowers:writing-plans` on document shape.** Take its scope check,
right-sizing, no-placeholders rule and self-review. Not "assume the engineer has zero context",
the inline code per step, or "repeat the code" — those build a standalone document, wrong for a
file read across many sessions, which cites `file:line` instead.

## 5. Executing

Read the header, **verify its "Verified" claims against current code** before trusting
them, then work only the current phase.

**Scout each phase before starting it** — paths move, interfaces change, work lands
elsewhere. Dispatch an `Explore` agent scoped to that phase, asking four things and nothing
else:

1. Do the named paths and symbols still exist, at the cited lines?
2. Do the phase's assumptions still hold?
3. Has any of this phase already been done?
4. Has adjacent work appeared that it must now account for — a new caller, a second
   implementation, a module overlapping its scope?

The fourth is the only one that catches what arrived while you weren't looking. Keep the brief
to these: a scout that reviews or proposes is a phase being redesigned by an agent that cannot
see the plan. Exception: a phase naming two or three concrete files.

Reconcile before the first edit — rewrite the phase to match what the scout found, then
stamp `Scouted: <date> @ <sha> — <drift, or "no drift">`. Drift that changes scope-out,
ordering, or whether the phase is still needed goes to the user in a line; that is a change
to the plan they agreed to.

The stamp is the skip condition: **skip the scout when `HEAD` still equals the stamped sha
and the tree is clean of changes you didn't make.** Resuming days later always scouts.

A phase doesn't start until the phases it depends on are green. Closing one: record
evidence per exit criterion, update the header, commit.
