---
name: agent-protocol
description: >
  Sub-agent delegation, the structured task-report format, sub-agent context budgeting,
  and orchestration responsibilities. Use before dispatching sub-agents, spawning parallel
  agents, or delegating work, and when reviewing what an agent reported back.
---

# Agent Protocol

> Applies to all delegation — built-in sub-agents, custom agents, and parallel dispatch.
> **Skip delegation** for tasks under ~50 lines with clear intent — do them directly. Sub-agents add overhead; use them when the gain outweighs the cost.
> **Exception:** the end-of-task independent reviewer always fires after code-modifying work, regardless of size.

**Core principle: delegate with structure, report with evidence, verify before claiming done.**

---

## 1. Orchestration Model

Claude is the **orchestrator**. The main context coordinates work, delegates to specialists, reviews results, and commits.

**When to delegate:** broad exploration, deep analysis, 2+ independent parallel tasks, specialized review (security, architecture, code quality), any task where the output is a report.

**When NOT to delegate:** simple edits under ~50 lines, tasks requiring ongoing user dialogue, work depending on context already loaded, sequential steps where each depends on the previous.

---

## 2. Delegation Reference

| Task                          | Delegate to                                                |
| ----------------------------- | ---------------------------------------------------------- |
| Broad codebase exploration    | `Explore` agent                                            |
| Architecture design, planning | `Plan` agent                                               |
| Deep feature analysis         | `feature-dev:code-explorer`                                |
| Implementation blueprint      | `feature-dev:code-architect`                               |
| Post-implementation review    | `feature-dev:code-reviewer`                                |
| Security-focused review       | `feature-dev:code-reviewer` (with explicit security brief) |
| 2+ independent tasks          | `superpowers:dispatching-parallel-agents`                  |

**Parallelization:** If tasks have no shared state or sequential dependency, launch them in one message with multiple `Agent` calls.

---

## 3. Task Reporting

Every delegated task must return a structured report.

### Required Report Format

```markdown
## Task Report: [task name]

- **Status:** done | blocked | partial
- **What changed:** [files created/modified/deleted — list each]
- **What was verified:** [concrete checks performed and their results]
- **Verification output:** [paste or summarize test output, lint output, or manual check result]
- **Blockers:** [none, or describe what's blocking and what's needed]
- **Assumptions made:** [any decisions the agent made without asking]
```

### Rules

- A task is not "done" without the Verification output field populated. Paste the evidence.
- Can't verify → Status must be `partial`, Blockers must explain what's needed.
- The orchestrator reviews every report before committing. Non-trivial assumptions → confirm with user.
- **Status definitions:** `done` = all criteria met, verified. `partial` = some work remains or verification incomplete. `blocked` = needs external input.

---

## 4. Sub-Agent Context

- **Prefer fresh sub-agent sessions** for exploration and analysis. Sub-agents get their own context window — use this to keep the main context lean.
- **Don't pass unnecessary context to sub-agents.** Give them the specific task and the specific files they need, not a dump of everything.
- **Sub-agents should return concise reports**, not raw output. The structured task report format (§3) is designed to carry maximum information in minimum tokens.

---

## 5. Orchestrator Responsibilities

1. **Define clear tasks** with specific acceptance criteria.
2. **Assign the right agent** — match task type to agent specialty.
3. **Review reports** — check that verification output matches claimed status.
4. **Synthesize results** — resolve conflicts between parallel agents, verify integration.
5. **Run final verification** — `superpowers:verification-before-completion` after all agent work is integrated.
6. **Communicate to user** — clear summary of what was done, verified, assumed, and what needs attention.

---

## 6. Common Delegation Patterns

**Parallel Feature Implementation:** Define tasks with clear boundaries → dispatch parallel agents → review reports → verify integration → commit.

**Research Then Implement:** Dispatch `Explore` → review findings → plan → dispatch implementation → dispatch `code-reviewer` for review.

**Fix With Regression Test:** Write failing test → dispatch fix agent → verify test passes → simplify → re-run tests.

---

## 7. Verification Checklist — Agent Gate

- [ ] Each delegated task has specific acceptance criteria
- [ ] Task report received from every agent with all required fields
- [ ] Verification output is actual evidence, not just "it works"
- [ ] Assumptions reviewed — non-trivial ones confirmed with user
- [ ] Integration verified between parallel agents' outputs
- [ ] `superpowers:verification-before-completion` run as final pass

---

_This skill is the single source of truth for agent delegation and task reporting. Where the resident session rules are terser, this skill wins._
