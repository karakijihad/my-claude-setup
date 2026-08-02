---
name: feedback-protocol
description: >
  Classifying a correction as one-off or pattern, and routing patterns into permanent
  rules. Use when correcting Claude's behavior, when a mistake recurs, or when updating
  any protocol, rule, or CLAUDE.md file.
---

# Feedback Loop Protocol

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

| Type of correction                                                  | Where to add it                                                        |
| ------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| General behavior (too verbose, wrong tone, asks too many questions) | the resident core in `hooks/core.md` |
| Security mistake (missed validation, exposed secret)                | the `security-protocol` skill — the relevant subfile            |
| Testing mistake (skipped tests, weak verification)                  | the `testing-protocol` skill                          |
| Delegation mistake (bad task definition, missing report fields)     | the `agent-protocol` skill                            |
| Git mistake (bad commit message, committed to main)                 | the `git-protocol` skill                              |
| Sub-agent context issue (over-stuffed brief, vague report)          | the `agent-protocol` skill — §4                       |
| Project-specific (wrong import style, misused library API)          | project `CLAUDE.md` — Gotchas section                                  |
| Tool misuse (wrong skill invoked, skipped Context7)                 | the resident core, or the triggering skill's `description` |

**Rule of thumb:** applies to any project → protocol file. Specific to this project → project `CLAUDE.md`.

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
  **Rule added:** resident core — "Verify external library APIs against Context7, never from memory."

- **Correction:** Agent report said "all tests pass" but didn't paste the output.
  **Classification:** Pattern.
  **Rule added:** the `agent-protocol` skill §3 — added "Paste the evidence" to the first reporting rule.

- **Correction:** Claude created a utility function that already existed in src/utils.
  **Classification:** One-off (unusual file structure).
  **Action:** Noted in session log. No protocol change.
```

---

_This skill is the single source of truth for the feedback loop process. Where the resident session rules are terser, this skill wins._
