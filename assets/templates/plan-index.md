# <Topic> — plan index

> Destination: `Docs/Plan/<topic>/INDEX.md`. The name is normative — `budget.sh` reads it.
> **Budget: 100 lines.** This header is the single source of truth for that number.
> Over budget means this file is carrying a chronicle. Delete it, don't compress it.
> **Never here:** a "Session history" or "What landed" section · phase detail.

Phase: 2 of 4 — migration · status: in-progress
Verified: phase 1 green — schema at `db/schema.sql:1-88`, migration test passing
Scouted: YYYY-MM-DD @ a1b2c3d — no drift
Next: backfill script, then the API cutover
Updated: YYYY-MM-DD

> Before starting any phase, scout it against the codebase first — brief and skip
> condition in `my-claude-setup:planning-protocol` §4. The plan is older than the code.

## Phases

| Phase | Status | Evidence | What it still owes |
|-|-|-|-|
| 1 — schema | green | `a1b2c3d` · `db/schema.sql:1-88` | — |
| 2 — migration | in-progress | — | the backfill script |

Status: `not-started` · `in-progress` · `awaiting-review` · `green` · `blocked`.

## Locked decisions

One line each — what a resuming session must not re-litigate, including rulings that
superseded earlier scope.

- YYYY-MM-DD — Backfill runs offline, not behind a flag. A flag needs a second write path.
