# Global Claude Configuration

**These guidelines bias toward caution over speed. For changes under ~50 lines with clear intent, skip to implement → verify → commit.**

---

## Think Before Acting

* State assumptions before implementing. Ask if unclear — don't guess silently.
* If multiple interpretations exist, present them. Don't pick one without saying so.
* If the simplest approach is being skipped, name why. Push back when warranted.
* If something is genuinely unclear, stop and ask. Don't produce plausible-looking wrong work.

## Code Discipline

* Write the minimum code that solves the problem. Nothing speculative.
* No features, abstractions, or error handling beyond what was asked.
* When editing: touch only what is necessary. Don't "improve" adjacent code.
* Match the existing style. If you notice dead code, mention it — don't delete it.
* Every changed line must trace to the user's request. If it can't, remove it.

## Goal-Driven Execution

Before starting any non-trivial task, define what "done" looks like:

```
1. [Step] → verify: [concrete check]
2. [Step] → verify: [concrete check]
```

Weak criteria ("make it work") require constant clarification. Strong criteria let you loop independently.

---

## Protocol Reference

**Read the relevant protocol before the relevant work. Don't guess from the summary — open the file.**

| Domain | File | Read before... |
|-|-|-|
| Security | `Docs/SecurityProtocol.md` | ...writing code that touches auth, endpoints, user input, file operations, data storage, or dependencies |
| Testing | `Docs/TestingProtocol.md` | ...writing tests, modifying test infrastructure, or verifying any non-trivial change |
| Agents | `Docs/AgentProtocol.md` | ...delegating tasks to sub-agents, setting up agent teams, or reviewing agent output |
| Git | `Docs/GitProtocol.md` | ...creating branches, committing, or interacting with git in any way |
| Context | `Docs/ContextProtocol.md` | ...when sessions run long, context approaches limits, or agent output starts degrading |
| Feedback | `Docs/FeedbackProtocol.md` | ...when correcting Claude, reviewing agent output, or updating any protocol file |

---

## Work Protocol

**Small tasks (<50 lines, clear intent):** implement → verify → commit. No ceremony needed.

**Larger tasks (multi-file, new features, unclear requirements):**

1. **Research** — Read relevant files before touching code. Use `Explore` agent for broad questions, `Grep`/`Glob` for targeted lookups. Verify external library APIs against current docs (use Context7), not memory. Never propose changes to files you haven't read.
2. **Plan** — New feature → `superpowers:brainstorming` first. Multi-step task → `superpowers:writing-plans`, Enter plan mode, and confirm plan before coding.
3. **Delegate** — See AgentProtocol.md. Don't do in main context what a sub-agent can do faster.
4. **Implement** — Execute via `superpowers:executing-plans` or `superpowers:subagent-driven-development` for parallel workstreams.
5. **Simplify** — Run `code-simplifier:code-simplifier` on modified files before verification.
6. **Verify** — See TestingProtocol.md. Security pass if relevant. Playwright for UI. Code trace for backend.
7. **Document then commit** — Update project docs. Write a session note if the project uses them. Then commit.

**Evidence before assertions. Never claim something works without completing step 6.**

---

## Agent Delegation Quick Reference

|Task|Delegate to|
|-|-|
|Broad codebase exploration|`Explore` agent|
|Architecture design|`Plan` agent|
|Deep feature analysis|`feature-dev:code-explorer`|
|Implementation blueprint|`feature-dev:code-architect`|
|Post-implementation review / security review|`feature-dev:code-reviewer`|
|2+ independent tasks|`superpowers:dispatching-parallel-agents`|

---

## Tool & Skill Reference

**Skills** — invoke via `Skill` tool before the relevant work:

|When|Skill|
|-|-|
|New feature or component|`superpowers:brainstorming`|
|Multi-step spec or plan|`superpowers:writing-plans`|
|Executing a plan|`superpowers:executing-plans`|
|Bug, failure, or unexpected behavior|`superpowers:systematic-debugging`|
|Before writing implementation|`superpowers:test-driven-development`|
|2+ parallel tasks|`superpowers:dispatching-parallel-agents`|
|Before marking complete / opening PR|`superpowers:verification-before-completion`|
|Implementation complete, ready to ship|`superpowers:finishing-a-development-branch`|
|Receiving code review|`superpowers:receiving-code-review`|
|After implementation, before commit|`code-simplifier:code-simplifier`|
|PR review / merge review|`pr-review-expert` (in skills/)|
|Dependency audit / license check|`dependency-auditor` (in skills/)|

**Tools** — invoke directly:

|When|Tool|
|-|-|
|External library API (accuracy matters)|`Context7`: resolve-library-id → query-docs|
|Any interactive UI change|Playwright: navigate → snapshot → interact → screenshot → console|
|Security review or guidance|`security-guidance`|
|Web scraping and crawling|`firecrawl`|
|UI/frontend design quality|`frontend-design`|

**If a referenced skill or tool is unavailable in this environment, proceed with the equivalent manual approach.**

---

## Verification Checklist

* [ ] All changed files read before editing
* [ ] Success criteria defined and met
* [ ] No unrequested code, features, or abstractions added
* [ ] `code-simplifier:code-simplifier` run on modified files
* [ ] `superpowers:verification-before-completion` invoked
* [ ] External API usage verified against current docs (Context7), not from memory
* [ ] UI changes verified with Playwright (DOM + zero console errors)

**Testing gate** → `Docs/TestingProtocol.md`
**Agent gate** → `Docs/AgentProtocol.md`
**Git gate** → `Docs/GitProtocol.md`
**Security gate** → `Docs/SecurityProtocol.md`

---

## Documentation (Per-Project)

**Suggested structure:**

```
Docs/Logs/
├── Sessions/           # One .md per day — the primary work log (Newest entry first per .md file)
├── CHANGELOG.md        # One line per version/phase (high-level only - Newest entry first per .md file) 
└── DOCLOG.md           # Durable architecture decisions only (Newest entry first per .md file)
```

**Ordering rule: newest first.** Within every doc file, the most recent content appears at the top of its section. In session logs, the latest stage goes first under "Done", the latest decision goes first under "Decisions", etc. This applies to CHANGELOG, DOCLOG, and session files equally.

**Session note template** (`Sessions/YYYY-MM-DD.md`):

```markdown
# Session YYYY-MM-DD — [phase or focus]

## Done
## Decisions
## Security Review
## Files Changed
## Commits
## Next
## Corrections → Protocol Updates (see FeedbackProtocol.md)
```

Write the session note as the last act before committing.

---

## How to Use

|Scenario|Action|
|-|-|
|New project|Run `/init`, then add project-specific sections (see project-template.md)|
|Existing `CLAUDE.md`|Merge sections not already present|
|Global standard|This file lives at `~/.claude/CLAUDE.md`|
|Personal overrides|Add to `.claude.local.md` (gitignore it)|

---

*Working if: diffs are clean, rewrites are rare, no secrets in git, no unparameterized queries, no unchecked auth, security issues caught before commit, hooks enforce what CLAUDE.md advises, context stays lean, corrections compound into permanent rules.*
