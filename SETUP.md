# Setup & Inventory

> Everything you need to install and configure for this system to work.
> If you're cloning this repo, follow the steps below in order.

---

## 1. Installation

Symlink the `.claude/` directory so edits here are immediately live everywhere:

```bash
# Clone
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Back up existing config if needed
mv ~/.claude ~/.claude-backup 2>/dev/null        # macOS/Linux
# Rename-Item "$env:USERPROFILE\.claude" "$env:USERPROFILE\.claude-backup"  # Windows (admin PowerShell)

# Symlink
ln -s /path/to/my-claude-setup/.claude ~/.claude   # macOS/Linux
# New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude" -Target "C:\path\to\my-claude-setup\.claude"  # Windows
```

---

## 2. Required Plugins

Install these via Claude Code. All are from the official marketplace.

```bash
# Core workflow — powers brainstorming, planning, execution, debugging, parallel agents
claude plugin install superpowers@claude-plugins-official

# Code quality — simplifies/cleans code after implementation
claude plugin install code-simplifier@claude-plugins-official

# Live documentation — verifies external library APIs against current docs
claude plugin install context7@claude-plugins-official

# Feature development agents — code-explorer, code-architect, code-reviewer
claude plugin install feature-dev@claude-plugins-official

# Code review — automated review on PRs
claude plugin install code-review@claude-plugins-official

# Security scanning — security guidance and vulnerability detection
claude plugin install security-guidance@claude-plugins-official

# Browser testing — Playwright for UI verification
claude plugin install playwright@claude-plugins-official

# Frontend design — UI/frontend design quality checks
claude plugin install frontend-design@claude-plugins-official

# Web scraping — Firecrawl for crawling and scraping
claude plugin install firecrawl@claude-plugins-official

# Git helpers — commit commands and workflows
claude plugin install commit-commands@claude-plugins-official

# CLAUDE.md management — tools for managing CLAUDE.md files
claude plugin install claude-md-management@claude-plugins-official

# Agent loop — Ralph loop for iterative agent work
claude plugin install ralph-loop@claude-plugins-official

# Skill creator — create and test custom skills
claude plugin install skill-creator@claude-plugins-official
```

After installing, restart Claude Code. Verify with `/plugins`.

---

## 3. Full Inventory

### Plugins (installed via marketplace)

| Plugin | Purpose | Used by |
|-|-|-|
| `superpowers` | Brainstorming, planning, execution, debugging, parallel agents, TDD, verification | CLAUDE.md Work Protocol, Tool & Skill Reference |
| `code-simplifier` | Code cleanup/simplification after implementation | CLAUDE.md Work Protocol step 5 |
| `context7` | External library API docs verification | CLAUDE.md Work Protocol step 1 |
| `feature-dev` | code-explorer, code-architect, code-reviewer agents | CLAUDE.md Agent Delegation, AgentProtocol.md |
| `code-review` | Automated PR/code review | GitProtocol.md §5 |
| `security-guidance` | Security review and vulnerability guidance | SecurityProtocol.md §8, CLAUDE.md Tool Reference |
| `playwright` | Browser/UI testing and verification | TestingProtocol.md §5, CLAUDE.md Verification Checklist |
| `frontend-design` | UI/frontend design quality | CLAUDE.md Tool Reference |
| `firecrawl` | Web scraping and crawling | CLAUDE.md Tool Reference |
| `commit-commands` | Git commit helpers | GitProtocol.md |
| `claude-md-management` | CLAUDE.md file management | General workflow |
| `ralph-loop` | Iterative agent work loop | Agent workflows |
| `skill-creator` | Create and test custom skills | Custom skill development |

### Custom Skills (in `skills/` directory)

| Skill | Purpose | Trigger phrases | Depends on |
|-|-|-|-|
| `pr-review-expert` | Blast radius, security scan, coverage delta, breaking changes for PRs | "review PR", "check this MR", "is this safe to merge" | `gh` CLI for GitHub, `glab` for GitLab |
| `dependency-auditor` | Vulnerability scanning, license compliance, upgrade planning | "audit deps", "check dependencies", "license check", "upgrade plan" | Python 3, project has package manifest |

> [!NOTE]
> `pr-review-expert` and `dependency-auditor` are inspired by [mar-antaya/my-claude-skills](https://github.com/mar-antaya/my-claude-skills)

### Protocol Docs (in `Docs/Protocols/` directory)

| Document | Governs | Read before... |
|-|-|-|
| `SecurityProtocol.md` | Input validation, auth, data protection, API security, dependencies | Writing code touching auth, endpoints, user input, file ops, data, deps |
| `TestingProtocol.md` | Test requirements, verification levels, coverage expectations | Writing tests, modifying test infra, verifying non-trivial changes |
| `AgentProtocol.md` | Delegation, task reporting, orchestration | Delegating to sub-agents, reviewing agent output |
| `GitProtocol.md` | Branching, commits, safety rules, PR process | Creating branches, committing, any git interaction |
| `ContextProtocol.md` | Context window management, compaction, session hygiene | Sessions running long, context approaching limits |
| `FeedbackProtocol.md` | Correction classification, rule creation, protocol updates | Correcting Claude, reviewing output, updating protocols |

### Hooks (in `.claude/settings.json`)

| Hook | Type | Purpose |
|-|-|-|
| Destructive command blocker | PreToolUse → Bash | Blocks `rm -rf /`, `DROP TABLE`, force push |
| Protected file guard | PreToolUse → Edit/Write | Blocks edits to `.env`, lockfiles, `.git/` |
| Secret-in-commit blocker | PreToolUse → Bash | Blocks commits containing api_key, secret, token, password |
| Auto-formatter | PostToolUse → Edit/Write | Runs prettier/black/gofmt/rustfmt on saved files |
| Test runner on stop | Stop | Runs `npm test` or `pytest` before task completion |
| Git context on start | SessionStart | Injects current branch and recent commits |
| Desktop notification | Notification | OS notification when Claude needs attention |

### Environment Variables (in `.claude/settings.json`)

| Variable | Value | Purpose |
|-|-|-|
| `MAX_THINKING_TOKENS` | 20000 | Extended thinking budget (default ~31200) |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | 50 | Auto-compact at 50% context usage (default ~75) |
| `CLAUDE_CODE_SUBAGENT_MODEL` | sonnet | Sub-agents use Sonnet (faster, cheaper) |

---

## 4. Per-Project Setup

After installing globally, each new project needs a thin project-level CLAUDE.md. See `project-template.md` for the template, or run `/init` and add the project-specific sections manually.
