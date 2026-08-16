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

**Four phases is the tripwire.** The second condition is an estimate, and the estimate runs
short in one direction only — "this will fit" is the normal way a plan doesn't get written,
and the cost lands later, on the session that resumes from a summary. So at four ordered
phases the default flips: offer, unless you can name the reason it all fits one window.
Under four, judge both conditions as above. Counting phases is checkable; predicting context
is not.

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
Scouted: YYYY-MM-DD @ a1b2c3d — phase 2 re-checked, no drift
Next: backfill script, then the API cutover
Updated: YYYY-MM-DD
```

Directly under the header, every plan file carries this line verbatim:

```markdown
> Before starting any phase, scout it against the codebase first — brief and skip
> condition in `my-claude-setup:planning-protocol` §4. The plan is older than the code.
```

It goes in the file because that is where a fresh session looks — a rule living only in
this skill is a rule the resuming session may never read. It stays a *pointer*, never a
copy of §4: a plan written months ago would otherwise carry a stale version of the
mechanism and be believed.

Each phase carries four things: **scope in · scope out · exit criteria · rollback**.
Scope-out is what stops the plan from growing. Exit criteria cite evidence — `file:line`,
test output, screenshot path — never "it works". Rollback is what you do when a phase
fails review, written before you need it.

**One plan is one file**, whatever the phase count. A plan that has grown long is a plan
with too many phases, not a plan that needs a directory — fix it by cutting scope or
closing phases, not by adding an index to navigate.

## 4. Executing

Opening a session against a plan: read the header, **verify its "Verified" claims against
current code** before trusting them, then work only the current phase.

**Scout each phase before starting it.** The phase was written against the codebase as it
was — paths move, interfaces change, work lands elsewhere. Dispatch an `Explore` agent
scoped to that phase's scope-in and exit criteria, asking four things and nothing else:

1. Do the named paths and symbols still exist, at the cited lines?
2. Do the phase's assumptions still hold?
3. Has any of this phase already been done?
4. Has adjacent work appeared that this phase must now account for — a new caller, a second
   implementation, a module that overlaps its scope?

Four, because the first three only ask whether what you wrote is still true; the fourth is
the only one that catches what arrived while you weren't looking. Keep the brief to these —
a scout that reviews or proposes is a phase being redesigned by an agent that cannot see
the plan.

`Explore` rather than grepping in the main context: the plan file exists *because* context
is scarce, and a sweep run here spends on file dumps the budget the phase itself needs. The
exception is a phase naming two or three concrete files — read those directly, the agent
round-trip costs more than the answer.

Then reconcile before the first edit: rewrite the phase to match what the scout found, then
stamp `Scouted: <date> @ <sha> — <drift, or "no drift">` in the header. Drift that changes
scope-out, ordering, or whether the phase is still needed goes to the user in a line — that
is a change to the plan they agreed to, not a detail to absorb.

The stamp is also the skip condition: **skip the scout when `HEAD` still equals the stamped
sha and the working tree is clean of changes you didn't make.** Closing phase 2 and opening
phase 3 in the same session, against a tree only you have touched, needs no scout — nothing
has moved. Resuming a plan days later always does.

A phase doesn't start until the phases it depends on are green — reviewed, evidence in the
file. Closing one: record evidence per exit criterion, update the header, commit.

Status vocabulary is fixed — `not-started` · `in-progress` · `awaiting-review` · `green` ·
`blocked`. Status lives in the header, not in prose.
