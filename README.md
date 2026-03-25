# my-claude-setup

Drop-in Claude Code configuration that enforces security, testing, git discipline, and structured agent delegation across every project. Symlink it to `~/.claude/` once, and every repo you open gets the full protocol stack automatically.

## What's inside

```
.claude/
├── CLAUDE.md              # Core rules — code discipline, workflow, tool/skill reference
├── settings.json          # Hooks, plugins, model config, env vars
├── Docs/
│   ├── SecurityProtocol.md    # Input validation, auth, data protection, API security
│   ├── TestingProtocol.md     # Test requirements, verification levels, coverage
│   ├── AgentProtocol.md       # Sub-agent delegation, task reporting, orchestration
│   ├── GitProtocol.md         # Branching, conventional commits, safety rules
│   ├── ContextProtocol.md     # Context window management, compaction, session hygiene
│   └── FeedbackProtocol.md    # Correction classification, rule updates, monthly review
└── skills/
    ├── pr-review-expert/      # Blast radius, security scan, coverage delta for PRs
    └── dependency-auditor/    # Vulnerability scanning, license compliance, upgrade planning

project-template.md            # Template for per-project CLAUDE.md files
SETUP.md                       # Full inventory of plugins, skills, hooks, and env vars
```

## Quick start

**1. Clone**

```bash
git clone https://github.com/YOUR_USERNAME/my-claude-setup.git
```

**2. Symlink to `~/.claude/`**

Windows (admin PowerShell):
```powershell
# Back up existing config if needed
Rename-Item "$env:USERPROFILE\.claude" "$env:USERPROFILE\.claude-backup" -ErrorAction SilentlyContinue

# Create symlink
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude" -Target "C:\path\to\my-claude-setup\.claude"
```

macOS / Linux:
```bash
# Back up existing config if needed
mv ~/.claude ~/.claude-backup 2>/dev/null

# Create symlink
ln -s /path/to/my-claude-setup/.claude ~/.claude
```

**3. Install plugins**

Open Claude Code and run each install command from [SETUP.md](SETUP.md#2-required-plugins).

**4. Per-project setup**

For each new project, create a thin project-level `CLAUDE.md` using the [project template](project-template.md):

```bash
cd ~/your-project
# Run /init for scaffolding, then add project-specific sections
```

The global config handles protocols, tools, and workflow. The project file only needs: architecture, key files, tech stack, commands, environment, and gotchas.

## How it works

Claude Code loads configuration in layers that stack (not override):

1. **`~/.claude/CLAUDE.md`** (global) — always active, every project
2. **`<project>/CLAUDE.md`** (project) — adds project-specific context
3. **`<project>/.claude.local.md`** (personal) — your overrides, gitignored

The global config provides the foundation: security-first code discipline, structured verification before any commit, agent delegation with evidence-based reporting, and context management to keep sessions lean. Project files add the specifics.

## What the hooks enforce

| Hook | What it does |
|------|-------------|
| Destructive command blocker | Blocks `rm -rf /`, `DROP TABLE`, force push |
| Protected file guard | Blocks edits to `.env`, lockfiles, `.git/` |
| Secret-in-commit blocker | Blocks commits containing secrets |
| Auto-formatter | Runs prettier/black/gofmt/rustfmt on every file save |
| Test runner on stop | Runs project tests before task completion |
| Git context on start | Injects current branch and recent commits |
| Desktop notification | OS notification when Claude needs attention |

## Plugins

See [SETUP.md](SETUP.md#3-full-inventory) for the complete inventory with descriptions and what references each plugin.

Core stack: superpowers, code-simplifier, context7, feature-dev, code-review, security-guidance, playwright, firecrawl.

## Protocol docs

Each protocol is a standalone reference document that Claude reads on-demand (not loaded into every session):

- **SecurityProtocol** — threat assessment, input validation, auth, session management, API security, dependency auditing, attack vector checklist
- **TestingProtocol** — when tests are required, test quality rules, verification levels, coverage expectations
- **AgentProtocol** — orchestration model, delegation reference, structured task reporting, verification gates
- **GitProtocol** — branching strategy, conventional commits, safety rules, PR process
- **ContextProtocol** — compaction rules, session hygiene, sub-agent context, warning signs
- **FeedbackProtocol** — correction classification, where to add rules, monthly review process

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
