# Backlog

> Destination: `Docs/Plan/BACKLOG.md`. Work identified but not yet planned.
> **Budget: 200 lines for the file, 5 lines for an entry.** This header is the single
> source of truth for both.
> **An entry that lands is DELETED in the pass that lands it** — not rewritten in the past
> tense, not moved to a `Closed` heading. A backlog that keeps its dead cannot answer the
> only question it exists for. Closing rationale worth keeping is one line in
> `Docs/Decisions/`.
> **Never here:** a `Closed` section · a `History` section.
>
> Already have `Deferred.md`? Same file, older name. Keep it; it is budgeted the same.

Sections are by what moves an entry out — that is what a reader is deciding.

## Open — unblocked, closes in a session

### A first-run test asserts a sentence the template no longer has

A copy rewrite removed the line and left the assertion, so it fails on a clean tree.
Ref: `tests/setup/test_first_run.py:41`.

## Blocked — real, waiting on a named trigger

### Two more readers of `runs.jsonl` have not moved to the shared reader

Trigger: the third reader, or the next format change. Ref: `src/store/runs.py:40`.

## Too large for a session — needs a plan folder

### The three god-modules

Trigger: when one next blocks a phase. Ref: `src/core/{engine,router,state}.py`.
