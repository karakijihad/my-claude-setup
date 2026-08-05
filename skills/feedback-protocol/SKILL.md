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
5. **Retire** — check whether the rule you just added made an older one redundant. See §5.

Step 5 is not optional bookkeeping. Steps 1–4 only ever *add*, and a loop that can only grow
ends as a rule set nobody reads — which is how instructions stop being followed. The point isn't
that every rule is temporary; it's that this loop has no other exit.

---

## 2. Where to Add Rules

| Type of correction                                                  | Where to add it                                                        |
| ------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| General behavior (too verbose, wrong tone, asks too many questions) | project `CLAUDE.md`. The resident core lives in the installed plugin, so editing it locally is overwritten by the next `/plugin update` — a rule that belongs there is a PR to the plugin, not a local edit |
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

## 4. Recording a correction

A correction that changed a rule **is a decision** — record it in `Docs/Decisions/YYYY-MM-DD.md`
with the rest of them. A one-off that changed nothing needs no record at all; writing it down is
how a decision log turns into a diary.

```markdown
## [HH:MM] — Verify library APIs against Context7

**Status:** accepted
**Decision** — Unfamiliar or version-sensitive library APIs get checked against Context7
rather than recalled.
**Why** — Third deprecated-React-API call this week, with Context7 installed and unused.
**Rejected** — "Always check every API." Forces a lookup for `JSON.parse`; the cost lands on
every call to buy accuracy on a few.
**Mechanism** — Resident core, research step.
```

If a correction is genuinely one-off — unusual context, an edge case that won't recur — fix it
and move on. Not every mistake is a rule waiting to be written, and treating them that way is
what produces instruction sets nobody can hold in their head.

---

## 5. Retiring rules

Adding is easy and feels productive; nothing else in this loop ever removes anything. So when
you add a rule, check whether it just obsoleted an older one.

Retire a rule when **any** of these is demonstrably true — not on a schedule, and never as a
quota to balance an addition:

- **Superseded** — the new rule covers the old one's case and more. Delete the old one.
- **Obsolete** — it corrected a model behaviour that no longer occurs. Rules written for a
  weaker model are the largest source of this, and they are invisible: they cost tokens every
  session and never fire.
- **Duplicated elsewhere** — the same instruction now lives in a skill that owns the topic.
  Keep one copy, in the place that owns it.
- **Never fired** — it has been in place for months and you cannot name an occasion it changed
  an outcome.

**Do not retire a rule merely because an unrelated one was added.** A one-in-one-out quota
deletes working guardrails to satisfy arithmetic. The trigger is evidence about *that* rule.

When you can't decide, keep it and note the doubt in the decision entry. A rule you're unsure
about costs tokens; a guardrail deleted on a hunch costs an incident.

---

_This skill is the single source of truth for the feedback loop process. Where the resident session rules are terser, this skill wins._
