# Plan

In-flight work only — multi-phase implementations that must survive a context reset.

One plan is one folder, and the names are normative: `budget.sh` reads them, and a file
renamed off this contract stops being budgeted.

```
Plan/
├── BACKLOG.md                    identified, not yet planned
└── 2026-04-17-feature-auth/
    ├── INDEX.md                  resumption header · phase table · locked decisions
    ├── phase-1-schema.md
    └── phase-2-migration.md
```

Work small enough to need no index stays one file: `Plan/YYYY-MM-DD-<topic>.md`.

Each phase carries **scope in · scope out · exit criteria · rollback**. Exit criteria cite
evidence — `file:line`, test output, screenshot path — never "it works".

`INDEX.md` carries this line under its header, because the code moves while the plan sits
still:

```markdown
> Before starting any phase, scout it against the codebase first — brief and skip condition in `my-claude-setup:planning-protocol` §4. The plan is older than the code.
```

**Delete a plan when its work lands.** Not `archive/` — a plan kept past its work reads as
live to the next session, and an archive is where a tree goes to grow without anyone
deciding to let it. Git holds history.

**Line budgets are in the templates** — `plan-index.md`, `plan-phase.md`, `backlog.md`.
An index over budget is carrying a chronicle that belongs in git log; delete it rather than
compress it. A phase over budget is a phase too large; split it. Superseded scope is
deleted outright, with one line surviving in the index's locked decisions.

`planning-protocol` §3 owns this layout and **overrides `superpowers:writing-plans` on
document shape** — take that skill's scope check, right-sizing and no-placeholders rule,
not its "assume the engineer has zero context" or its inlined code per step. Those build a
standalone document, which is right for a one-shot handoff and wrong for a file read across
many sessions.
