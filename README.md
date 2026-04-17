# my-claude-setup

Drop-in Claude Code configuration that enforces security, testing, git discipline, and structured agent delegation across every project. Symlink it to `~/.claude/` once, and every repo you open gets the full protocol stack automatically.

## What's inside

```
.claude/
├── CLAUDE.md                     # Core rules — code discipline, workflow, tool/skill reference
├── settings.json                 # Hooks, plugins, model config, env vars
├── Docs/Protocols/
│   ├── Security/                 # Folder-split — one subfile per domain
│   │   ├── README.md
│   │   ├── 01-Threat-Model.md
│   │   ├── 02-Input.md
│   │   ├── 03-Auth.md
│   │   ├── 04-Data.md
│   │   ├── 05-API.md
│   │   ├── 06-Dependencies.md
│   │   ├── 07-AI-Agents.md       # Prompt injection, MCP trust, skill supply chain
│   │   ├── 08-Attack-Vectors.md
│   │   ├── 09-Review-Gate.md
│   │   └── 10-Verification.md
│   ├── TestingProtocol.md        # Test requirements, verification levels, coverage
│   ├── AgentProtocol.md          # Sub-agent delegation, task reporting, orchestration
│   ├── GitProtocol.md            # Branching, conventional commits, safety rules
│   ├── ContextProtocol.md        # Context window management, compaction, session hygiene
│   └── FeedbackProtocol.md       # Correction classification, rule routing, protocol updates
├── Templates/                    # Bootstrap skeletons for new projects
│   ├── project-CLAUDE.md
│   ├── session-note.md
│   ├── doclog-entry.md
│   ├── changelog-year.md
│   ├── audit-README.md
│   └── Docs-skeleton/            # Full Docs/ tree to copy into new projects
├── hooks/
│   └── protocol-reminder.sh      # UserPromptSubmit hook — brevity rule + protocol routing
└── skills/
    ├── pr-review-expert/         # Blast radius, security scan, coverage delta for PRs
    ├── dependency-auditor/       # Vulnerability scanning, license compliance, upgrade planning
    └── skill-security-auditor/   # Audit skills before installation

project-template.md               # Pointer to .claude/Templates/
SETUP.md                          # Full inventory of plugins, skills, hooks, and env vars
```

## Per-project `Docs/` convention

Each project follows a folder-based layout that keeps append-only records bounded:

```
Docs/
├── Changelog/YYYY.md             # One file per year, newest at top
├── Doclog/YYYY-MM-DD.md          # One file per day — all decisions that day
├── Sessions/YYYY-MM-DD.md        # One file per day — work log
├── Audit/{agent}/YYYY-MM-DD/     # Review artifacts — claude/ and codex/
│   └── audit-{N}.md
├── Plan/                         # Stage checklists for in-flight work
├── Logs/CODEMAP.md               # File map — updated on structural changes
└── Protocols/                    # Project-specific overrides (rare)
```

**Rules:** newest first in every file; audits are evidence, not decisions; decisions belong in Doclog or Sessions.

## Quick start

**1. Clone**

```bash
git clone https://github.com/YOUR_USERNAME/my-claude-setup.git
```

**2. Symlink to `~/.claude/`**

Windows (admin PowerShell):
```powershell
Rename-Item "$env:USERPROFILE\.claude" "$env:USERPROFILE\.claude-backup" -ErrorAction SilentlyContinue
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude" -Target "C:\path\to\my-claude-setup\.claude"
```

macOS / Linux:
```bash
mv ~/.claude ~/.claude-backup 2>/dev/null
ln -s /path/to/my-claude-setup/.claude ~/.claude
```

**3. Install plugins**

Open Claude Code and run each install command from [SETUP.md](SETUP.md#2-required-plugins).

**4. Bootstrap a new project**

```bash
cd your-project
cp ~/.claude/Templates/project-CLAUDE.md ./CLAUDE.md
cp -r ~/.claude/Templates/Docs-skeleton ./Docs
# Fill in project specifics in CLAUDE.md.
```

The global config handles protocols, tools, and workflow. The project file only needs architecture, key files, tech stack, commands, environment, and gotchas.

## How it works

Claude Code loads configuration in layers that stack (not override):

1. **`~/.claude/CLAUDE.md`** (global) — always active, every project
2. **`<project>/CLAUDE.md`** (project) — adds project-specific context
3. **`<project>/.claude.local.md`** (personal) — your overrides, gitignored

The global config provides the foundation: security-first code discipline, structured verification before any commit, agent delegation with evidence-based reporting, and context management to keep sessions lean. Project files add the specifics.

## What the hooks enforce

| Hook | What it does |
|------|-------------|
| `protocol-reminder.sh` | Injects brevity rule on every prompt; routes keywords to protocol files |
| Destructive command blocker | Blocks `rm -rf /`, `DROP TABLE`, force push |
| Protected file guard | Blocks edits to `.env`, lockfiles, `.git/` |
| Secret-in-commit blocker | Blocks commits containing secrets |
| Auto-formatter | Runs prettier/black/gofmt/rustfmt on every file save |
| Test runner on stop | Runs project tests before task completion |
| Git context on start | Injects current branch and recent commits |
| Desktop notification | OS notification when Claude needs attention |

## Plugins

See [SETUP.md](SETUP.md#3-full-inventory) for the complete inventory.

Core stack: superpowers, code-simplifier, context7, feature-dev, code-review, security-guidance, playwright, firecrawl, skill-security-auditor.

## Protocol docs

Each protocol is a standalone reference document that Claude reads on-demand (not loaded into every session):

- **Security/** — folder-split: threat model, input validation, auth, data protection, API security, dependencies, AI/agent workflow, attack vectors, review gate, verification
- **TestingProtocol** — when tests are required, test quality rules, verification levels
- **AgentProtocol** — orchestration model, delegation reference, structured task reporting, verification gates
- **GitProtocol** — branching strategy, conventional commits, safety rules, PR process
- **ContextProtocol** — compaction rules, session hygiene, sub-agent context, warning signs
- **FeedbackProtocol** — correction classification, where to add rules, protocol routing table

## Updating

Because `~/.claude/` is symlinked to this repo, any edits here are immediately live. Push changes to keep all your machines in sync:

```bash
cd /path/to/my-claude-setup
git add -A && git commit -m "docs: update security protocol"
git push
```

On other machines: `git pull` and you're current.

## License

MIT
