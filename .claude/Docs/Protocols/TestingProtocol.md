# Testing & Verification Protocol

> Referenced by `~/.claude/CLAUDE.md`. Read this before writing tests, modifying test infrastructure, or verifying any non-trivial change.
> Applies to all project types — web apps, APIs, CLIs, mobile, serverless, microservices, libraries.
> **Skip the checklist** for changes under ~50 lines with clear intent and no branching logic — verify by running the code, then commit.

**Core principle: nothing ships without execution evidence. "I reviewed the code" is not verification.**

---

## 1. When Tests Are Required

Tests are **required** for:

- Any new function, method, endpoint, or component with branching logic or edge cases
- Any bug fix — write a regression test that fails without the fix, passes with it
- Any refactor that changes behavior (not pure renames, moves, or formatting)
- Any code that touches auth, payments, or data persistence
- Any public API surface (exported functions, REST endpoints, GraphQL resolvers)

**Exception:** changes under ~50 lines with clear, linear intent — run the code, confirm it works, commit. No formal test required unless the logic is non-obvious.

Tests are **optional** for:

- Pure configuration changes (env vars, build settings, CI config)
- Documentation-only changes
- One-off scripts that won't be reused
- Cosmetic UI changes with no logic — but still verify with Playwright

If you're unsure whether a change needs tests, it needs tests.

---

## 2. Testing Workflow

Follow this order. Steps are not interchangeable.

1. **Before implementation:** Define test cases that capture the "done" criteria. Use `superpowers:test-driven-development` for non-trivial features. If the feature has edge cases, list them now — not after you've written the code.
2. **During implementation:** Run tests incrementally as you build. Don't batch all testing to the end. If a test fails mid-implementation, fix the code — don't comment out the test.
3. **After implementation, before simplification:** All tests must pass. If a test fails, fix the code — don't delete the test. If a test is wrong, fix the test and document why.
4. **After simplification:** Run the full test suite again. `code-simplifier:code-simplifier` must not introduce regressions. If it does, revert the simplification.

---

## 3. Test Quality Rules

- **Deterministic.** No flaky tests. No `sleep()` or `setTimeout()` as synchronization. If you need to wait for async operations, use proper awaits, polling with timeouts, or event-driven signals.
- **Isolated.** Tests must not depend on external services unless explicitly marked as integration tests. Unit tests mock external boundaries; integration tests use real (or containerized) dependencies.
- **One thing per test.** Each test should test one behavior. Name it so the failure message tells you exactly what broke — `test_expired_token_returns_401` not `test_auth`.
- **Mock boundaries, not internals.** Mock the network, filesystem, clock, and external APIs. Don't mock the class you're testing or its private methods.
- **No test interdependence.** Tests must pass in any order. No test should depend on state left by a previous test.
- **Clean up after yourself.** Tests that create files, database records, or network connections must clean them up.

---

## 4. Coverage Expectations

No hard percentage target. Coverage must include:

- All happy paths (the normal success case for every feature)
- All error paths the user specified (what should happen on bad input, missing auth, network failure)
- All edge cases identified during planning (empty inputs, boundary values, concurrent access)

**The practical test:** if you can describe a scenario that isn't tested, add a test for it.

---

## 5. Verification Levels

Use the **strongest applicable level** from this table:

| Level | When to use | What it looks like |
|-------|------------|-------------------|
| **Automated tests** | Code with testable logic | Run the test suite, paste the output |
| **Playwright** | Any UI change | Navigate → snapshot → assert DOM state + zero console errors |
| **Code trace** | Backend logic, data flow | Walk through the code path with concrete inputs, show expected vs actual |
| **Manual check** | Config changes, infra, one-off scripts | Describe exactly what you checked and what you observed |
| **Build/lint** | Any code change (minimum bar) | Compile/lint must pass with zero warnings in changed files |

Multiple levels can apply. A new API endpoint needs automated tests, a build check, and potentially a code trace.

---

## 6. Verification Rules

- Every task report must include which verification level was used and the output.
- Pre-existing test failures are blockers — not a reason to skip testing.
- "I reviewed the code" is not verification. Verification requires execution or concrete trace.
- Multi-file changes require integration verification — not just individual file checks.
- The orchestrator runs `superpowers:verification-before-completion` as a final pass, in addition to task-level verification.

---

## 7. Verification Failures

- If verification fails, the task goes back to implementation. Do not commit with known failures.
- If verification is impossible in the current environment, document exactly what can't be verified, why, and what would be needed. Flag it for the user.
- Partial verification is acceptable when documented.

---

## 8. Test Infrastructure Rules

- Don't modify test infrastructure without explicit permission.
- New test dependencies require justification — same scrutiny as production dependencies.
- Test data lives with tests — fixtures and factories go in the test directory.
- Integration tests must be clearly separated from unit tests.

---

## 9. Verification Checklist — Testing & Verification Gate

- [ ] Test cases defined before or during implementation
- [ ] Tests written for all required scenarios (see §1)
- [ ] All tests passing — zero failures
- [ ] Verification level selected from §5 and evidence included in task report
- [ ] Tests re-run after `code-simplifier:code-simplifier` — no regressions
- [ ] Multi-file changes verified at the integration level
- [ ] `superpowers:verification-before-completion` invoked as final pass
- [ ] Any unverifiable items documented with reason and flagged for user

---

*This document is the single source of truth for testing and verification. If `~/.claude/CLAUDE.md` contradicts it, this file wins.*
