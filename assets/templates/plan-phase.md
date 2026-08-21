# Phase N — <slug>

> Destination: `Docs/Plan/<topic>/phase-N-<slug>.md`. The `phase-` prefix is normative.
> **Budget: 200 lines.** This header is the single source of truth for that number.
> **Over budget means the phase is too large, not the prose too loose.** Split it, where
> each half has its own exit criterion.
> **Never here:** superseded scope kept struck through · backlog items · an implementation
> inlined so the file reads standalone. Cite `file:line`.

**Scope in** — paths and symbols, not paragraphs.

- `src/api/users.py:120-180` — cursor pagination replaces offset

**Scope out** — what stops this phase growing.

- The admin endpoints. Same helper, different contract; phase 4.

**Exit criteria** — each cites evidence. Never "it works".

- [ ] `pytest tests/api/test_users.py -q` passes — paste the summary line
- [ ] `src/api/users.py` no longer imports `offset_page`

**Rollback** — written before it is needed.

Revert the phase commit; the old helper stays until phase 4.

---

When scope changes: delete what it replaced, and put one line in `INDEX.md` under locked
decisions.
