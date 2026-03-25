# Feedback Loop Protocol

> Referenced by `CLAUDE.md`. Read this when correcting Claude, reviewing agent output, or updating any protocol file.
> Applies to all interactions where Claude's output needs correction or improvement.

**Core principle: every correction is either a one-off or a pattern. Patterns become permanent rules.**

---

## 1. The Compounding Engineering Loop

When Claude makes a mistake or produces suboptimal output:

1. **Correct it** — fix the immediate problem.
2. **Classify it** — is this a one-off (unusual context, edge case) or a pattern (likely to recur)?
3. **Route it:**
   - **One-off** → capture in the session note under "Corrections" and move on.
   - **Pattern** → add a rule to the appropriate file (see §2) so it never happens again.
4. **Verify** — in the next occurrence, check if the rule was followed.

This loop is the single highest-leverage practice for improving Claude's output over time. Every rule you add makes every future session better.

---

## 2. Where to Add Rules

| Type of correction | Where to add it |
|-------------------|----------------|
| General behavior (too verbose, wrong tone, asks too many questions) | `CLAUDE.md` — Think Before Acting or Code Discipline section |
| Security mistake (missed validation, exposed secret) | `Docs/SecurityProtocol.md` |
| Testing mistake (skipped tests, weak verification) | `Docs/TestingProtocol.md` |
| Delegation mistake (bad task definition, missing report fields) | `Docs/AgentProtocol.md` |
| Git mistake (bad commit message, committed to main) | `Docs/GitProtocol.md` |
| Context issue (lost track of plan, degraded quality) | `Docs/ContextProtocol.md` |
| Project-specific (wrong import style, misused library API) | `CLAUDE.md` — project Gotchas section |
| Tool misuse (wrong skill invoked, skipped Context7) | `CLAUDE.md` — Tool & Skill Reference section |

**Rule of thumb:** if the correction applies to any project, it goes in a protocol file. If it's specific to this project, it goes in CLAUDE.md.

---

## 3. How to Write Good Rules

- **Be specific.** "Write better tests" is useless. "Every test name must describe the scenario and expected outcome — `test_expired_token_returns_401` not `test_auth`" is actionable.
- **Include the wrong behavior and the right behavior.** Claude learns faster from contrast: "Don't do X. Instead, do Y."
- **Keep it short.** One rule = one sentence or two. If it needs a paragraph, it's a procedure, not a rule — put it in the relevant protocol section.
- **Use emphasis sparingly.** If everything is IMPORTANT or MUST, nothing is. Reserve emphasis for rules Claude has violated more than once.

---

## 4. Session Note Correction Format

In every session note, include a "Corrections → Protocol Updates" section:

```markdown
## Corrections → Protocol Updates

- **Correction:** Claude used deprecated React API despite Context7 being available.
  **Classification:** Pattern (third time this week).
  **Rule added:** `CLAUDE.md` Work Protocol step 1 — "Verify external library APIs against current docs (use Context7), not memory."

- **Correction:** Agent report said "all tests pass" but didn't paste the output.
  **Classification:** Pattern.
  **Rule added:** `Docs/AgentProtocol.md` §3 — added "Paste the evidence" to the first reporting rule.

- **Correction:** Claude created a utility function that already existed in src/utils.
  **Classification:** One-off (unusual file structure).
  **Action:** Noted in session log. No protocol change.
```

---

## 5. Monthly Protocol Review

Once a month (or at project milestones), review all protocol files:

- **Prune dead rules.** If a rule addresses a problem that hasn't occurred in 4+ weeks, consider removing it. Bloated protocols degrade instruction-following (see ContextProtocol.md §1).
- **Consolidate overlapping rules.** Two rules that say the same thing slightly differently should be merged.
- **Promote battle-tested rules.** If a project-specific Gotcha turns out to apply universally, move it to the relevant protocol file.
- **Check rule effectiveness.** For rules added in the last month, did they actually prevent the problem from recurring? If not, the rule might be too vague — sharpen it.

---

## 6. PR-Driven Feedback (For Teams)

If working in a team:

- When a code reviewer flags an issue that Claude should have caught, add the rule and tag the commit with the protocol file that was updated.
- Treat protocol updates as part of the PR — they're as important as the code fix.
- Share learnings across the team by keeping protocol files in version control.

---

*This document is the single source of truth for the feedback loop process. If CLAUDE.md contradicts it, this file wins.*
