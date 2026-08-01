# my-claude-setup

Security, testing, git, and delegation discipline for Claude Code, packaged as a plugin.

Install it once and every repo you open gets the same rules: minimum-code discipline, a
mandatory independent review at the end of any code-modifying task, safety hooks that block
destructive commands and staged secrets, and seven protocol references that load only when
they're relevant.

```
/plugin marketplace add karakijihad/my-claude-setup
/plugin install my-claude-setup@my-claude-setup
```

Then **restart Claude Code** — installing a plugin mid-session fires no `SessionStart`, so nothing
happens until you do. On the first sessions after install, the plugin checks what is actually
missing — companion plugins you don't have, recommended settings not yet applied, leftovers from
an older symlink install — and offers to walk you through it. It runs nothing without your
agreement, and stays silent once there is nothing to fix.

Claude Code has no install-time hook event, so this rides on `SessionStart`, tracked by
`~/.claude/.my-claude-setup-onboarded`. It appears for up to three sessions rather than exactly
one: `SessionStart` context arrives with no user turn attached, so the notice is only acted on
once you type something, and a notice spent on a session you closed immediately would otherwise
be lost for good. It stops as soon as nothing is missing. Delete that file to see it again.

## Prerequisites

| Requirement | Needed by | Check |
|-|-|-|
| Git | everything | `git --version` |
| Python 3 | `session-start` hook, `skill-security-auditor` | `python -c "import sys; print(sys.version_info[:2])"` |
| Node.js | `ccstatusline` status line (optional) | `node --version` |

Every Python entry point in this plugin runs through `hooks/py.sh`, which *executes* each of
`python3`, `python`, and `py -3` and uses the first that actually works.

<details>
<summary><b>Windows: the <code>python3</code> Store-stub trap</b></summary>

Windows ships 0-byte *app execution alias* stubs at
`%LOCALAPPDATA%\Microsoft\WindowsApps\python.exe` and `python3.exe`. They aren't interpreters —
they exit 9009 with "Python was not found" and open the Microsoft Store.

Installing via winget or python.org does **not** displace them for `python3`, because those
builds ship `python.exe` and `py.exe` but **no `python3.exe`**. So `python3` stays broken even
after a successful install.

```powershell
winget install --id Python.Python.3.13 -e
```

This plugin tolerates that by probing rather than trusting the name. **Any skill or hook you add
must do the same — never call `python3` directly.**

To make `python3` work for your own shell use, relying on the installer prepending its directory
to PATH ahead of `WindowsApps` (verify with `$env:PATH -split ';'`):

```powershell
$PY = "$env:LOCALAPPDATA\Programs\Python\Python313"
Copy-Item "$PY\python.exe" "$PY\python3.exe"
```

Exit code 1618 during install means another MSI holds the installer mutex. Don't kill
`msiexec`; reboot and retry.

</details>

## What's inside

```
.claude-plugin/     marketplace.json, plugin.json
hooks/              hooks.json + scripts
skills/             9 skills
commands/           setup, bootstrap-project, unlink-legacy
assets/templates/   project CLAUDE.md, session note, doclog, changelog, audit README, Docs skeleton
```

### Hooks

| Hook | Event | What it does |
|-|-|-|
| `session-start.sh` → `.py` → `core.md` | SessionStart | Injects the resident core (its text lives in `core.md`, read by the Python path and re-emitted via jq by the fallback, so there is one copy) — brevity, code discipline, the confirm-first threshold, the fast path, the independent-review rule — plus current branch and recent commits, and the one-time onboarding check. If no Python is available it falls back to a reduced core rather than emitting nothing |
| `brevity.sh` | UserPromptSubmit | Reinforces brevity, which decays over a long session. One `printf`, no stdin parse, no interpreter |
| `guard.sh` | PreToolUse | Blocks `rm -rf /`, force-push, `reset --hard`, `clean -f`, `branch -D` (but not `-d`), `DROP`/`TRUNCATE TABLE`; blocks writes to `.env*` (except `.env.example`), lockfiles, and `.git/`; scans the **staged diff** for value-shaped secrets on commit |
| `notify.sh` | Notification | Desktop notification — notify-send, osascript, or PowerShell |

`guard.sh` is one script doing what three used to. The old ones each spawned a shell and a JSON
parse on *every* Bash call just to determine they had nothing to do.

Two hooks were deliberately removed: a pre-commit test runner that cost up to 120s per commit
and discarded its own output, and a formatter that ran `npx prettier` after every write —
rewriting Markdown as it was authored and desyncing editor state.

Hooks that need event fields parse stdin with `lib-parse.sh` (jq if present, otherwise a Python
located by `py.sh`), so they work without `jq` installed. `brevity.sh` is the exception — it
prints a fixed string and deliberately reads nothing.

### Skills

Invoke by name, or let the description trigger them.

| Skill | Covers |
|-|-|
| `security-protocol` | Threat model, input validation, auth, data, API, dependencies, AI/agent security — 10 references |
| `testing-protocol` | When tests are required, quality rules, coverage, verification levels |
| `git-protocol` | Conventional commits, safety rules, PR process — and asks before branching rather than assuming |
| `agent-protocol` | Delegation, structured task reports, orchestration |
| `context-protocol` | Compaction thresholds, session hygiene, sub-agent budgeting |
| `feedback-protocol` | Turning corrections into permanent rules |
| `project-docs` | The `Docs/` convention, line budgets, templates |
| `dependency-auditor` | Vulnerability scanning, license compliance, upgrade planning via each ecosystem's native tools |
| `skill-security-auditor` | Static audit of a skill before you install it |

`security-protocol` §7 (AI/agent security) is the one to read before adding an MCP server or
installing someone else's skill — prompt injection, tool authority, supply chain, transcript
hygiene.

### Commands

| Command | Does |
|-|-|
| `/setup` | Merges the recommended `settings.json` keys. Shows a diff, asks first, idempotent |
| `/bootstrap-project` | Scaffolds a project `CLAUDE.md` and the `Docs/` tree |
| `/unlink-legacy` | Finds and removes an old symlink installation |

## Companion plugins

The protocols name these by default. Nothing hard-fails without them — Claude is told to say so
and fall back to the manual equivalent — but the workflow is thinner.

```
/plugin install feature-dev@claude-plugins-official        # code-explorer, code-architect, code-reviewer
/plugin install superpowers@claude-plugins-official        # brainstorming, plans, TDD, verification
/plugin install context7@claude-plugins-official           # live library docs instead of model memory
/plugin install security-guidance@claude-plugins-official  # security review pass, /security-review
/plugin install code-review@claude-plugins-official        # PR review
/plugin install code-simplifier@claude-plugins-official    # post-implementation cleanup
/plugin install playwright@claude-plugins-official         # UI verification

/plugin marketplace add karakijihad/trio-cc                # trio needs its own marketplace
/plugin install trio@trio-cc                               # independent Codex audit
```

This list, the companion sentence at the end of `hooks/core.md`, and `COMPANIONS` in
`hooks/onboarding.py` name the same set. `hooks/test-hooks.sh` asserts the last two agree; keep
this one with them.

| Plugin | Referenced by |
|-|-|
| `feature-dev` | The independent-review rule names `feature-dev:code-reviewer` as its default reviewer — **the one that matters most** |
| `superpowers` | The larger-task sequence: brainstorming, writing-plans, test-driven-development, verification-before-completion |
| `context7` | The resident rule to verify external library APIs against docs rather than model memory |
| `security-guidance` | `security-protocol` §9 review gate |
| `code-review` | `git-protocol` §5 PR process |
| `code-simplifier` | The simplify step, and `testing-protocol` §2.4 (re-run tests after it) |
| `playwright` | `testing-protocol` §5 — the verification level for any UI change |

Optional second opinion — an independent Codex audit that adjudicates its findings against the
code, from a separate marketplace:

```
/plugin marketplace add karakijihad/trio-cc
/plugin install trio@trio-cc
```

## Per-project docs

Projects following this setup keep an append-only `Docs/` tree — newest first, one file per day,
folder-based so nothing grows unbounded:

```
Docs/
├── Changelog/YYYY-MM-DD.md
├── Doclog/YYYY-MM-DD.md          decisions
├── Sessions/YYYY-MM-DD.md        work log
├── Audit/{agent}/YYYY-MM-DD/     review evidence
├── Plan/                         in-flight stage checklists
├── Logs/CODEMAP.md
└── Protocols/                    project overrides, rare
```

Decisions live in `Doclog/` and `Sessions/`; `Audit/` is evidence, never a decision by itself.
`/bootstrap-project` creates all of it. See the `project-docs` skill for line budgets.

## Migrating from the symlink version

1. `/plugin marketplace add karakijihad/my-claude-setup` and install.
2. `/unlink-legacy` — it identifies every link before removing anything, and refuses to delete
   real files or your `settings.json`.
3. `/setup`.
4. Restart Claude Code.

## Updating

```
/plugin update my-claude-setup@my-claude-setup
```

## License

MIT
