# Global Claude Configuration

**For changes under ~50 lines with clear intent: implement → verify → commit. No ceremony.**

---

## Think Before Acting

* State assumptions before implementing. Ask if unclear — don't guess silently.
* If multiple interpretations exist, present them. Don't pick one without saying so.
* If the simplest approach is being skipped, name why. Push back when warranted.
* **When to stop and ask:** if a decision affects >2 files, is hard to reverse, or requires a structural assumption — confirm first. Small changes: decide and say so.
* For non-trivial tasks, define done criteria before starting: `Step → verify: concrete check`.

## Code Discipline

* Write the minimum code that solves the problem. Nothing speculative.
* No features, abstractions, or error handling beyond what was asked.
* Touch only what is necessary. Don't improve adjacent code. Match existing style.
* Every changed line must trace to the request. If it can't, remove it.

## Protocol Reference

Read before the relevant work. Open the file — don't guess from the summary.

| Domain | File | Trigger |
|-|-|-|
| Security | `~/.claude/Docs/Protocols/SecurityProtocol.md` | auth, endpoints, user input, file ops, data, dependencies |
| Testing | `~/.claude/Docs/Protocols/TestingProtocol.md` | writing tests, verifying non-trivial changes |
| Agents | `~/.claude/Docs/Protocols/AgentProtocol.md` | delegating to sub-agents, reviewing agent output |
| Git | `~/.claude/Docs/Protocols/GitProtocol.md` | branches, commits, any git interaction |
| Context | `~/.claude/Docs/Protocols/ContextProtocol.md` | long sessions, context approaching limits |
| Feedback | `~/.claude/Docs/Protocols/FeedbackProtocol.md` | correcting Claude, updating protocols |

---

## Work Protocol

**Small (<50 lines):** implement → verify → commit.

**Larger tasks:**

1. **Research** — Read files before touching code. `Explore` for broad questions, `Grep`/`Glob` for targeted lookups. Verify library APIs via Context7, not memory.
2. **Plan** — New feature → `superpowers:brainstorming`. Multi-step → `superpowers:writing-plans` + plan mode.
3. **Delegate** — See AgentProtocol.md. Don't do in main context what a sub-agent can do faster.
4. **Implement** — `superpowers:executing-plans` or `superpowers:subagent-driven-development`.
5. **Simplify** — `code-simplifier:code-simplifier` on modified files.
6. **Verify** — TestingProtocol.md. Security pass if relevant. Playwright for UI. Code trace for backend.
7. **Document then commit** — Session note if project uses them. Then commit.

**Evidence before assertions. Never claim something works without completing step 6.**

---

## Agent Delegation

| Task | Delegate to |
|-|-|
| Broad codebase exploration | `Explore` agent |
| Architecture design | `Plan` agent |
| Deep feature analysis | `feature-dev:code-explorer` |
| Implementation blueprint | `feature-dev:code-architect` |
| Post-implementation / security review | `feature-dev:code-reviewer` |
| 2+ independent tasks | `superpowers:dispatching-parallel-agents` |

---

## Skills & Tools

**Skills** — invoke via `Skill` tool before the relevant work:

| When | Skill |
|-|-|
| New feature or component | `superpowers:brainstorming` |
| Multi-step spec or plan | `superpowers:writing-plans` |
| Executing a plan | `superpowers:executing-plans` |
| Bug, failure, or unexpected behavior | `superpowers:systematic-debugging` |
| Before writing implementation | `superpowers:test-driven-development` |
| 2+ parallel tasks | `superpowers:dispatching-parallel-agents` |
| Before marking complete / opening PR | `superpowers:verification-before-completion` |
| Implementation complete, ready to ship | `superpowers:finishing-a-development-branch` |
| Receiving code review | `superpowers:receiving-code-review` |
| After implementation, before commit | `code-simplifier:code-simplifier` |
| PR review / merge review | `pr-review-expert` |
| Dependency audit / license check | `dependency-auditor` |

**Tools** — invoke directly:

| When | Tool |
|-|-|
| External library API (accuracy matters) | Context7: resolve-library-id → query-docs |
| Any interactive UI change | Playwright: navigate → snapshot → interact → screenshot → console |
| Security review or guidance | `security-guidance` |
| Web scraping and crawling | `firecrawl` |
| UI/frontend design quality | `frontend-design` |

If a skill or tool is unavailable, proceed with the equivalent manual approach.

---

## Verification Checklist

* [ ] All changed files read before editing
* [ ] Success criteria defined and met
* [ ] No unrequested code, features, or abstractions added
* [ ] `code-simplifier:code-simplifier` run on modified files
* [ ] `superpowers:verification-before-completion` invoked
* [ ] External API usage verified against current docs (Context7), not from memory
* [ ] UI changes verified with Playwright (DOM + zero console errors)

**Testing gate** → `~/.claude/Docs/Protocols/TestingProtocol.md`
**Agent gate** → `~/.claude/Docs/Protocols/AgentProtocol.md`
**Git gate** → `~/.claude/Docs/Protocols/GitProtocol.md`
**Security gate** → `~/.claude/Docs/Protocols/SecurityProtocol.md`

---

## Docs (Per-Project)

| Path | Purpose |
|------|---------|
| `Docs/CHANGELOG.md` | Semver changelog (newest first) |
| `Docs/DOCLOG.md` | Architecture decisions (newest first) |
| `Docs/Sessions/YYYY-MM-DD.md` | Per-day work logs (newest first) |
| `Docs/Logs/CODEMAP.md` | Codebase map — files, roles, line counts, data flows |
| `Docs/Logs/` | Build logs, benchmarks |

**Newest first** in all doc files. **Update CODEMAP** after any structural change (files created, deleted, moved, restructured).

**Session note** (`Sessions/YYYY-MM-DD.md`): Done · Decisions · Security Review · Files Changed · Commits · Next · Corrections → Protocol Updates (see `~/.claude/Docs/Protocols/FeedbackProtocol.md`). Write before committing.
