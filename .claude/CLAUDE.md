# Global Claude Configuration

**For changes under ~50 lines with clear intent: implement → verify → commit. No ceremony.**

---

## Think Before Acting

* State assumptions before implementing. Ask if unclear — don't guess silently.
* If multiple interpretations exist, present them. Don't pick one without saying so.
* If the simplest approach is being skipped, name why. Push back when warranted.
* **When to stop and ask:** decisions that affect >2 files, are hard to reverse, or require a structural assumption — confirm first. Small changes: decide and say so.
* For non-trivial tasks, define done criteria before starting: `Step → verify: concrete check`.

## Code Discipline

* Write the minimum code that solves the problem. Nothing speculative.
* No features, abstractions, or error handling beyond what was asked.
* Touch only what is necessary. Don't improve adjacent code. Match existing style.
* Every changed line must trace to the request. If it can't, remove it.

> Brevity rule is enforced per-prompt by `hooks/protocol-reminder.sh`, not duplicated here.

---

## Protocol Reference

Read the file before relevant work — don't guess from the summary.

| Domain | File | Trigger |
|-|-|-|
| Security | `~/.claude/Docs/Protocols/Security/README.md` | auth, endpoints, user input, file ops, data, dependencies, AI/agent tooling (folder — read the relevant subfile) |
| Testing | `~/.claude/Docs/Protocols/TestingProtocol.md` | writing tests, verifying non-trivial changes |
| Agents | `~/.claude/Docs/Protocols/AgentProtocol.md` | delegating to sub-agents, reviewing agent output |
| Git | `~/.claude/Docs/Protocols/GitProtocol.md` | branches, commits, any git interaction |
| Context | `~/.claude/Docs/Protocols/ContextProtocol.md` | long sessions, context approaching limits |
| Feedback | `~/.claude/Docs/Protocols/FeedbackProtocol.md` | correcting Claude, updating protocols |

Each protocol owns its own verification gate. When protocols and this file disagree, protocols win.

---

## Work Protocol

**Small (<50 lines):** implement → verify → commit.

**Larger tasks:**

1. **Research** — Read files before touching code. `Explore` for broad questions, `Grep`/`Glob` for targeted lookups. Verify library APIs via Context7, not memory.
2. **Plan** — New feature → `superpowers:brainstorming`. Multi-step → `superpowers:writing-plans` + plan mode.
3. **Delegate** — See `AgentProtocol.md`. Don't do in main context what a sub-agent can do faster.
4. **Implement** — `superpowers:executing-plans` or `superpowers:subagent-driven-development`.
5. **Simplify** — `code-simplifier:code-simplifier` on modified files.
6. **Verify** — TestingProtocol. Security pass if relevant. Playwright for UI. Code trace for backend.
7. **Document then commit** — Session note if project uses them. Then commit.

**Evidence before assertions. Never claim something works without completing step 6.**

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
| Auditing a skill before install | `skill-security-auditor` |

Delegation map (which agent does what): `AgentProtocol.md` §2.

**Tools** — invoke directly:

| When | Tool |
|-|-|
| External library API (accuracy matters) | Context7: resolve-library-id → query-docs |
| Any interactive UI change | Playwright: navigate → snapshot → interact → screenshot → console |
| Web scraping and crawling | `firecrawl` |
| UI/frontend design quality | `frontend-design` |

If a skill or tool is unavailable, proceed with the equivalent manual approach.

---

## Pre-Commit Verification

* [ ] All changed files read before editing
* [ ] Success criteria defined and met
* [ ] No unrequested code, features, or abstractions added
* [ ] `code-simplifier:code-simplifier` run on modified files
* [ ] `superpowers:verification-before-completion` invoked
* [ ] External API usage verified against current docs (Context7), not from memory
* [ ] UI changes verified with Playwright (DOM + zero console errors)

Full gates live inside each protocol's own checklist.

---

## Per-Project Docs

**Rule: newest first in every append-only file. Dated files are one-per-day. Folder-based to prevent bloat.**

```
Docs/
├── Changelog/
│   ├── README.md              # Index: version bumps, links by date
│   └── YYYY-MM-DD.md          # One file per day — all changelog entries that day
├── Doclog/
│   ├── README.md              # Index: decision titles by date
│   └── YYYY-MM-DD.md          # One file per day — all decisions that day
├── Sessions/
│   └── YYYY-MM-DD.md          # One file per day — work log
├── Audit/
│   ├── README.md              # How audits are produced and reconciled
│   ├── claude/YYYY-MM-DD/audit-{N}.md
│   └── codex/YYYY-MM-DD/audit-{N}.md
├── Plan/                      # Stage checklists for in-flight work
├── Logs/
│   ├── CODEMAP.md             # File map — roles, line counts, data flows
│   └── …                      # Build logs, benchmarks
└── Protocols/                 # Project-specific overrides only (rare)
```

**Authoritative records** (what decisions were accepted): `Doclog/`, `Sessions/`. **Supporting evidence** (what reviewers found): `Audit/`. An audit is never a decision by itself — see `Docs/Audit/README.md`.

**CODEMAP** updates after any structural change (files created, deleted, moved, restructured).

**Session note** (`Sessions/YYYY-MM-DD.md`): Done · Decisions · Security Review · Files Changed · Commits · Next · Corrections → Protocol Updates. Write before committing. See template in `~/.claude/Templates/session-note.md`.

**Bootstrap a new project** from `~/.claude/Templates/`:

| Template | Purpose |
|-|-|
| `project-CLAUDE.md` | Per-project CLAUDE.md skeleton |
| `session-note.md` | Daily session log |
| `doclog-entry.md` | Architecture decision record |
| `changelog-entry.md` | Daily changelog file |
| `audit-README.md` | Copy into `Docs/Audit/README.md` |
| `Docs-skeleton/` | Full folder tree to copy into a new project |
