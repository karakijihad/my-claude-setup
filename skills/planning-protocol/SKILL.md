---
name: planning-protocol
description: >
  When to stop and write a plan before implementing, and what that plan must contain to
  survive a context reset. Use before starting work that breaks into ordered phases, when
  a task won't fit one context window, when the user asks for a plan, roadmap, or phased
  breakdown, and when resuming work against an existing plan file in Docs/Plan/.
---

# Planning Protocol

## 1. When to offer

Both must hold:

- The work breaks into **ordered phases** — phase N can't start until N-1 is done.
- It **won't fit one context window** — you'd resume from a summary, not from memory.

Either alone is not enough. A 20-file rename is one phase. A 3-file change can be four.

Don't offer when the work is under ~50 lines, is pure research, finishes in one clear
commit, or already has a plan file — extend that one instead of opening a second.

## 2. The offer

Stop before the first edit. Name the phases you actually see in one sentence, then ask.
No pitch, no pre-summary.

> "This is four ordered phases — schema, migration, API, UI — and it won't fit one
> context. Plan file first, or straight in?"

Declined → proceed immediately, no gate, no second mention. Re-offer **once**, and only
on a concrete overrun: phases discovered exceed phases estimated, or one phase spills the
context. A second decline is final for the task.

## 3. Drafting

Accepted → invoke `superpowers:writing-plans`, output to `Docs/Plan/YYYY-MM-DD-<topic>.md`.
Without superpowers installed, say so once and write the same file by hand.

The file opens with the resumption header — the reason it exists:

```markdown
Phase: 2 of 4 — migration · status: in-progress
Verified: phase 1 green — schema at `db/schema.sql:1-88`, migration test passing
Next: backfill script, then the API cutover
Updated: YYYY-MM-DD
```

Each phase carries four things: **scope in · scope out · exit criteria · rollback**.
Scope-out is what stops the plan from growing. Exit criteria cite evidence — `file:line`,
test output, screenshot path — never "it works". Rollback is what you do when a phase
fails review, written before you need it.

Past ~6 phases, split to `Docs/Plan/<topic>/` — `INDEX.md` holding the status table and
session history, one file per phase.

## 4. Executing

Opening a session against a plan: read the header, **verify its "Verified" claims against
current code** before trusting them, then work only the current phase.

A phase doesn't start until the phases it depends on are green — reviewed, evidence in the
file. Closing one: record evidence per exit criterion, update the header, commit.

Status vocabulary is fixed — `not-started` · `in-progress` · `awaiting-review` · `green` ·
`blocked`. Status lives in the header, not in prose.
