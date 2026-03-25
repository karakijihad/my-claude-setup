# Agent Protocol

> Referenced by `CLAUDE.md`. Read this before delegating tasks to sub-agents, setting up agent teams, or reviewing agent output.
> Applies to all delegation — built-in sub-agents, custom agents, parallel dispatch, and agent teams.

**Core principle: delegate with structure, report with evidence, verify before claiming done.**

---

## 1. Orchestration Model

Claude is the **orchestrator**. The main context coordinates work, delegates to specialists, reviews results, and commits.

**When to delegate:** broad exploration, deep analysis, 2+ independent parallel tasks, specialized review (security, architecture, code quality), any task where the output is a report.

**When NOT to delegate:** simple edits under ~50 lines, tasks requiring ongoing user dialogue, work depending on context already loaded, sequential steps where each depends on the previous.

---

## 2. Delegation Reference

|Task|Delegate to|
|-|-|
|Broad codebase exploration|`Explore` agent|
|Architecture design, planning|`Plan` agent|
|Deep feature analysis|`feature-dev:code-explorer`|
|Implementation blueprint|`feature-dev:code-architect`|
|Post-implementation review|`feature-dev:code-reviewer`|
|Security-focused review|`feature-dev:code-reviewer` (with explicit security brief)|
|2+ independent tasks|`superpowers:dispatching-parallel-agents`|

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

## 4. Orchestrator Responsibilities

1. **Define clear tasks** with specific acceptance criteria.
2. **Assign the right agent** — match task type to agent specialty.
3. **Review reports** — check that verification output matches claimed status.
4. **Synthesize results** — resolve conflicts between parallel agents, verify integration.
5. **Run final verification** — `superpowers:verification-before-completion` after all agent work is integrated.
6. **Communicate to user** — clear summary of what was done, verified, assumed, and what needs attention.

---

## 5. Common Delegation Patterns

**Parallel Feature Implementation:** Define tasks with clear boundaries → dispatch parallel agents → review reports → verify integration → commit.

**Research Then Implement:** Dispatch `Explore` → review findings → plan → dispatch implementation → dispatch `code-reviewer` for review.

**Fix With Regression Test:** Write failing test → dispatch fix agent → verify test passes → simplify → re-run tests.

---

## 6. Agent Teams (Multi-Session) — Placeholder

> Experimental. Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` enabled.

Agent teams spawn separate Claude Code instances with their own context windows that can communicate with each other. Use when: 3+ independent workstreams, agents need to read each other's output mid-flight, or visual monitoring (split-pane via tmux/iTerm2) is valuable.

**Key rules:** Never manually close a teammate's pane. Always shut down through the lead. All reporting rules (§3) apply to teammates. The lead synthesizes all reports before reporting to the user.

---

## 7. Verification Checklist — Agent Gate

- [ ] Each delegated task has specific acceptance criteria
- [ ] Task report received from every agent with all required fields
- [ ] Verification output is actual evidence, not just "it works"
- [ ] Assumptions reviewed — non-trivial ones confirmed with user
- [ ] Integration verified between parallel agents' outputs
- [ ] `superpowers:verification-before-completion` run as final pass

---

*This document is the single source of truth for agent delegation and task reporting. If CLAUDE.md contradicts it, this file wins.*
