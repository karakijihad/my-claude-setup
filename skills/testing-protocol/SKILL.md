---
name: testing-protocol
description: >
  Use before writing or modifying tests or test infrastructure, and before claiming any
  non-trivial change is verified.
---

# Testing & Verification Protocol

Generic testing advice is not here — deterministic tests, mocked boundaries, one behaviour
per case, clean fixtures. This skill holds only what this setup decides differently, which
is two things: **where the fast path ends**, and **what earns a test at all**.

**Core principle: nothing ships without execution evidence. "I reviewed the code" is not
verification.**

---

## 1. The tier boundary, and where TDD takes over

`superpowers:test-driven-development`'s Iron Law — *no production code without a failing
test first* — is written to admit no exceptions, and names "skip TDD just this once" as
rationalization. It is right, **from Tier 2 upward**: once work earns an independent
reviewer it earns a failing test first, and you do not negotiate with the Iron Law there.

At **Tier 1** — under ~50 lines, clear linear intent, nothing sensitive — this protocol wins
and TDD is not invoked at all. Run the code, confirm it works, commit. That is the whole
point of a fast path.

Resolve it by tier, never by argument in the moment. Two skills reaching opposite
conclusions on the same change means you got the tier wrong, not that one of them is broken.

Regardless of tier, a test is **required** for: any bug fix (a regression test that fails
without the fix), anything touching auth, payments or data persistence, and any public API
surface.

---

## 2. What earns a test — and what earns deletion

**The practical test, which decides both what to add and what to keep:** what plausible
defect would make this test fail, what would that defect cost, and does an existing test
already catch it?

A scenario you can describe is not a reason on its own; most describable scenarios cost
nothing when they break. Reuse or replace a case before adding another. Verifying something
once does not oblige you to keep a regression test for it forever.

Hold the three classes at different strengths:

- **Safety** — anything that blocks a destructive command, scans for a secret, preserves a
  user's settings, or deletes files. Keeps every distinct failure mechanism, every known
  regression, and the counterexamples proving it does not over-block. Never trimmed to hit
  a line target.
- **Contracts** — output a consumer actually reads, a registration, an interpreter
  fallback, a file one component writes and another reads. One case per supported path and
  per materially different failure.
- **Advisory** — a reminder, a warning's wording, display formatting. Four cases: it works,
  it stays quiet when it should, it fails gracefully, and any state transition that matters.
  Past that, name the consequence or don't write it.

A suite that outgrows the thing it tests stops being read, and a suite nobody reads is not
coverage. When it does, cut advisory first and safety never.

---

## 3. Verification

Use the **strongest applicable level**, and put its output in the report:

| Level | When | What it looks like |
|-------|------|-------------------|
| **Automated tests** | Code with testable logic | Run the suite, paste the output |
| **Playwright** | Any UI change | Navigate → snapshot → assert DOM state + zero console errors |
| **Code trace** | Backend logic, data flow | Walk the path with concrete inputs, show expected vs actual |
| **Manual check** | Config, infra, one-off scripts | Say exactly what you checked and what you observed |
| **Build/lint** | Any code change (minimum bar) | Zero warnings in changed files |

- Pre-existing failures are blockers, not an excuse to skip.
- Multi-file changes need integration verification — separately-green does not compose.
- Verification impossible here? Say exactly what couldn't be checked, why, and what would
  be needed. Partial verification is fine when it is stated as partial.
- If verification fails, the work goes back to implementation. Don't commit known failures,
  and don't delete a test to make a suite green.

---

*Where the resident session rules are terser, this skill wins.*
