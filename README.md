# my-claude-setup

A rail for how Claude Code works, packaged as a plugin.

It adds no capabilities. It decides how the ones you have get used: when to plan, when to fan out
agents, which companion plugin owns which decision, what a review must clear before work is called
done, and where a project's documents live. It is for people who run long Claude Code sessions on
real repositories and want those decisions made the same way every session, on every machine.

```
/plugin marketplace add karakijihad/my-claude-setup
/plugin install my-claude-setup@my-claude-setup
```

Then **restart Claude Code**. Installing a plugin mid-session fires no `SessionStart`, so nothing
happens until you do.

## What you get on first session

- **The resident core**, about 800 tokens of rules injected at every session start: brevity, code
  discipline, the fast path for small changes, the review ladder, the fan-out rule, the companion
  roster. Six protocol skills load later, on demand.
- **Hooks that guard and remind**: destructive commands and secret-bearing commits are blocked,
  oversized project docs are flagged, a push triggers a CI reminder, and context fill is reported.
- **A first-run notice**, for up to three sessions. It lists what is missing (companion plugins,
  recommended settings, leftovers from an older install) and offers to walk you through it with
  `/my-claude-setup:setup`. It runs nothing without your agreement and stops once there is nothing
  to fix. Delete `~/.claude/.my-claude-setup-onboarded` to see it again.

## Requirements

| Requirement | Needed by | Check |
|-|-|-|
| Claude Code | everything. Developed against 2.1.273; `context-watch` needs the `PostToolBatch` hook event | `claude --version` |
| bash | every hook (`"shell": "bash"`). On Windows that is Git for Windows | `bash --version` |
| Python 3 or `jq` | parsing hook payloads. Without both, `guard.sh` skips its checks and says so on stderr, and session start emits only a reduced core | `jq --version` |
| Git | branch context, the staged-diff secret scan, CI reminders | `git --version` |
| Node.js | the status line only (optional) | `node --version` |

Every Python entry point goes through `hooks/py.sh`, which *executes* each of `python3`, `python`
and `py -3` and uses the first that works.

<details>
<summary><b>Windows: the <code>python3</code> Store-stub trap</b></summary>

Windows ships 0-byte *app execution alias* stubs at
`%LOCALAPPDATA%\Microsoft\WindowsApps\python.exe` and `python3.exe`. They are not interpreters:
they exit 9009 with "Python was not found" and open the Microsoft Store.

Installing via winget or python.org does **not** displace them for `python3`, because those builds
ship `python.exe` and `py.exe` but **no `python3.exe`**. So `python3` stays broken after a
successful install. This plugin tolerates that by probing rather than trusting the name.

```powershell
winget install --id Python.Python.3.13 -e
```

To make `python3` work in your own shell:

```powershell
$PY = "$env:LOCALAPPDATA\Programs\Python\Python313"
Copy-Item "$PY\python.exe" "$PY\python3.exe"
```

Exit code 1618 during install means another MSI holds the installer mutex. Do not kill `msiexec`;
reboot and retry.

</details>

## What it does

### Hooks

Five hooks, registered in `hooks/hooks.json`. All fail open: a hook that errors exits 0. Only
`guard.sh` ever blocks (exit 2).

| Hook | Event | What it does |
|-|-|-|
| `session-start.sh` | SessionStart | Injects `hooks/core.md`, the current git branch, a notice when the Tier-2 reviewer plugin is not enabled, the first-run notice, and which model subagents and the advisor run on. Also seeds `.claude/settings.local.json` (see Privacy) and, after a plugin update, repairs the status-line pointer, prunes superseded cached releases and reports what changed. Falls back to `core.md` through `jq`, then to a reduced core, if Python is missing |
| `guard.sh` | PreToolUse | Blocks `rm -rf` on `/`, `~`, `*` or `$HOME`, force-push, `reset --hard`, `clean -f`, `checkout -- `, `branch -D` (not `-d`), `DROP TABLE`/`DROP DATABASE`/`TRUNCATE TABLE`, piping `curl`/`wget` into a shell, `git add -f`, and commits that skip git hooks; the PowerShell equivalents of `rm -rf`; writes to `.env*` (except `.env.example`, `.env.sample`, `.env.template`), lockfiles and `.git/`. On commit it scans the **staged diff** for value-shaped secrets and credential material |
| `budget.sh` | PostToolUse | Warns when a file under a `Docs/` folder outgrows its budget: lines for plans, indexes, backlogs and code maps; estimated tokens for a handoff. Ratcheted: it speaks on the first crossing and again only when an edit makes it worse. Never blocks |
| `post-push.sh` | PostToolUse | After a `git push`, names the commit SHA and points at the check command under `## CI` in the repo's `CLAUDE.md`. It does not detect CI providers and does not claim the push landed. Silent for `git -C` / `--git-dir` pushes aimed at another repo |
| `context-watch.sh` | PostToolBatch | Reads the context fill that the status line writes to a state file (no hook payload carries it). Silent below the soft threshold. At the soft threshold, one heads-up line. At the handoff budget, a directive to write the handoff and tell you to start a fresh session, repeated for each further 5% of the window. The budget is 50% of the window by default; see Configuration. Silent for subagents. Needs the status line installed |

The core ends every code-modifying task on one of three review rungs, and skipping one needs a
stated reason:

| Tier | Reviewer | Fires when |
|-|-|-|
| **1** | Claude re-reads its own diff | One file, under ~50 lines, nothing sensitive |
| **2** | `feature-dev:code-reviewer`, a fresh agent | Default for any real change |
| **3** | `trio`: Codex audits, Claude adjudicates | Auth, secrets, payments, migrations, deletion; more than 5 files; a release; or reviewer and diff disagree |

### Skills

Six protocol skills, loaded when their description matches the situation.

| Skill | Covers |
|-|-|
| `project-docs` | The `Docs/` convention, line budgets, the handoff, templates |
| `planning-protocol` | When phased work earns a plan file, and why a plan is a guide rather than a specification |
| `agent-protocol` | The brief a sub-agent gets and the report it owes back |
| `testing-protocol` | Where the fast path ends and TDD takes over, and what earns a test at all |
| `git-protocol` | Don't branch unless asked, what to confirm first, checking CI by SHA |
| `security-protocol` | Escalation, and agent/MCP tool-authority rules. Security expertise belongs to the `security-guidance` companion |

### Agents

| Agent | For |
|-|-|
| `my-claude-setup:worker` | Delegated work: writing code on an assigned file set, research, running tests |
| `my-claude-setup:advisor` | Advice-only second opinion on an open design question. Never writes code |

Both run at `effort: high`, which can only be set on an agent definition, not per dispatch. Neither
card pins a model, so the model set in Configuration applies.

### Commands

| Command | What it does |
|-|-|
| `/my-claude-setup:setup` | **Part 1, machine:** adds marketplaces, installs the companions, merges recommended `settings.json` keys, tunes `security-guidance` so its checks don't double-fire, installs the status line. **Part 2, project:** scaffolds `CLAUDE.md` and `Docs/`, or surveys an existing repo and reports before writing. Shows a diff, asks first, idempotent. Never rewrites an existing `CLAUDE.md` |
| `/my-claude-setup:status` | Read-only report: hooks registered and present, settings in effect, knob values, which companions are enabled, how this project's `Docs/` stands |

## Companion plugins

The protocols name these by default. They are optional. Without one, Claude is told to say so once
and use the manual equivalent, so nothing hard-fails and the workflow is thinner. Missing
`feature-dev` is the one that matters most: session start then says the Tier-2 rung has no agent
behind it. `/my-claude-setup:setup` installs all of them, marketplaces included (`trio` comes from
`karakijihad/trio-cc`, the rest from `claude-plugins-official`).

Each has one job, so no two contend for the same decision.

| Plugin | Its one job | Fires when |
|-|-|-|
| `feature-dev` | **Tier-2 reviewer**: `code-reviewer`, the ladder's default | Any real change |
| `trio` | **Tier-3 audit**: Codex reviews read-only through parallel lenses, Claude adjudicates. `trio-consult` gives advice before a choice | Auth, secrets, payments, migrations, deletion; more than 5 files; a release; or reviewer and diff disagree |
| `superpowers` | **Process**: brainstorming, writing-plans, test-driven-development, verification-before-completion | Larger tasks only, never the fast path |
| `security-guidance` | **Tier-3 security pass**, and the security expertise this plugin deliberately does not carry | Auth, secrets, credentials, untrusted input |
| `context7` | **Unfamiliar or version-sensitive APIs** | Reaching for an API you can't verify from the repo |
| `playwright` | **Changed interactive or rendering behaviour** | Not every CSS tweak |

## Configuration

Everything is optional. Set variables under `env` in `~/.claude/settings.json` (or a project's
`.claude/settings.json`), then restart the session.

```json
{
  "env": {
    "CLAUDE_HANDOFF_PCT": "40",
    "CLAUDE_HANDOFF_DOC_TOKENS": "8000"
  }
}
```

**Context and handoff**

| Variable | Controls | Default |
|-|-|-|
| `CLAUDE_HANDOFF_PCT` | The handoff budget, as a percentage of the context window (1-100) | `50` |
| `CLAUDE_HANDOFF_BUDGET` | The same budget as an absolute token count. Wins over the percentage when both are set | unset |
| `CLAUDE_HANDOFF_SOFT_PCT` | When the one heads-up line fires, as a percentage of the window. A value at or above the handoff budget is ignored | 80% of the budget (40% of the window with defaults) |
| `CLAUDE_HANDOFF_DOC_TOKENS` | How long a written handoff may be before `budget.sh` warns, in estimated tokens (4 characters each) | `5000` |

These take digits only (`50`, not `50%` or `8k`). A malformed or zero value falls back to the
default silently, because hooks fail open and a typo looks the same as an unset variable. The
5%-of-window re-report cadence once past the budget is not configurable.

**Models**

| Variable | Controls | Default |
|-|-|-|
| `CLAUDE_CODE_SUBAGENT_MODEL` | Claude Code's subagent model: an alias (`sonnet`), which follows releases, or a full id, which pins one. Empty or `ask`: Claude asks first | `sonnet` |
| `CLAUDE_ADVISOR_MODEL` | Model for `my-claude-setup:advisor` consults, dispatched as its alias | `fable` |

Session start writes both into each git repo's `.claude/settings.local.json` (missing keys only),
so a repo can differ from your user settings. Edit that file to change them per repo.

**Status line and debugging**

| Variable or file | Effect | Default |
|-|-|-|
| `STATUSLINE_GIT_CHANGES=1` | Adds a dirty-file count to line 3, at the cost of one `git status` per render | off |
| `STATUSLINE_DEBUG` (any value) | The launcher prints why it failed to stderr instead of staying silent | off |
| `~/.claude/statusline-debug` (empty file) | Next render writes the raw payload to `~/.claude/statusline-payload.json` | absent |
| `~/.claude/.my-claude-setup-debug` (empty file) | The update repair logs a failure to `~/.claude/.my-claude-setup-debug.log` | absent |

The plugin also reads `CLAUDE_PROJECT_DIR` and `CLAUDE_PLUGIN_ROOT` (set by Claude Code),
`USERPROFILE`/`HOME` to find `~/.claude`, and `TMPDIR` for the budget ratchet. `/my-claude-setup:status`
prints the values actually in effect.

## Status line

![The status line: model and effort, machine memory, session spend, context, session input and output tokens, cache-hit rate, the active skill, branch and lines edited](assets/statusline.svg)

Three lines: model, effort, memory and session spend; context, token totals, cache-hit rate and the
active skill; branch and lines edited this session. Plain node, no dependencies. Colour is a
signal: context, cache-hit rate and memory scale green, amber, red. The cache ratio floors rather
than rounds, so 99.6% is never shown as 100%.

`/my-claude-setup:setup` copies `assets/statusline-launcher.mjs` to `~/.claude/statusline.mjs` and
points `statusLine` in `settings.json` at that path. The launcher finds the current release at run
time, because pointing at the plugin's own directory goes stale on every update, quietly. It is
also the only component Claude Code hands the context window to, so it writes the state file
`context-watch.sh` reads. Without it, `context-watch.sh` stays silent.

## Privacy and data

**Nothing leaves your machine from this plugin's code.** No script in `hooks/` or `assets/` opens a
network connection, and none sends telemetry. Text a hook injects into the session (the core, the
branch name, `[context]` lines, reminders) becomes part of the conversation context, which Claude
Code sends to Anthropic like everything else in a session.

**What it reads**

- Hook payloads from Claude Code: the tool command or file path (`guard.sh`, `budget.sh`,
  `post-push.sh`) and the session id (`context-watch.sh`).
- `~/.claude/settings.json` (`enabledPlugins`, `hooks`, `statusLine`) and
  `~/.claude/plugins/installed_plugins.json`.
- The existence of `~/.claude/Docs`, `hooks`, `Templates` and `CLAUDE.md` (old-install detection).
- `.git/HEAD` for the branch name, read from disk. Commit messages are never injected.
- The staged diff, on `git commit` only, to scan for secrets. The diff is not stored.
- Status line only: the session transcript (the last 8 MB) to find the most recent skill name, and
  free and total memory.

**What it writes**

| Path | Written by | Content |
|-|-|-|
| `~/.claude/cache/my-claude-setup/<session>.json` | status line | Session id, tokens used, window size, percent. Mode 0600; files older than 7 days are pruned |
| `~/.claude/cache/my-claude-setup/<session>.band` | `context-watch.sh` | The last reported context state, so it reports once per crossing |
| `$TMPDIR/my-claude-setup-budget/` (or `/tmp/...`) | `budget.sh` | One line-count mark per over-budget doc |
| `~/.claude/.my-claude-setup-onboarded` | onboarding | A counter, 0-3 |
| `~/.claude/.my-claude-setup-version`, `.my-claude-setup-last-update.md` | update repair | Last seen plugin version; a copy of the last update report |
| `~/.claude/.my-claude-setup-model-news` | session start | Timestamp, to nudge about newer models at most weekly (only with a pinned full model id) |
| `~/.claude/.my-claude-setup-python` | `py.sh` | Path of the Python interpreter that worked |
| `~/.claude/statusline.mjs` | update repair, `/setup` | Copy of the launcher |
| `<repo>/.claude/settings.local.json` and `.git/info/exclude` | session start | The two model keys (missing ones only); a line excluding that file from git. Git repos only |
| `~/.claude/settings.json` | update repair | Only repoints a `statusLine` that is pinned inside this plugin's cache. `/setup` edits it after showing a diff |
| `~/.claude/plugins/cache/my-claude-setup/<old version>/` | update repair | Deletes superseded cached releases of this plugin only |
| `~/.claude/statusline-payload.json`, `.my-claude-setup-debug.log` | debug switches | Only when you create the flag files above |

**Subprocesses**: `git rev-parse HEAD` (`post-push.sh`), `git diff --cached` (`guard.sh`, on commit),
`git check-ignore` and `git rev-parse --git-path` (`session-start.py`, only when it seeds
`.claude/settings.local.json`), `git status` (status line, only with `STATUSLINE_GIT_CHANGES=1`).

## Updating

`claude plugin update my-claude-setup`, then restart. The next session reports what changed and
repairs what the update broke.

## Uninstall

```
/plugin uninstall my-claude-setup@my-claude-setup
/plugin marketplace remove my-claude-setup
```

That removes the plugin and its hooks. Companion plugins stay; remove them with
`claude plugin uninstall <name>` if you want them gone. Files it left behind, all safe to delete:

- `~/.claude/cache/my-claude-setup/`, `~/.claude/statusline.mjs`, and the dotfiles
  `~/.claude/.my-claude-setup-*`
- `$TMPDIR/my-claude-setup-budget/`
- In each repo: the `CLAUDE_CODE_SUBAGENT_MODEL` and `CLAUDE_ADVISOR_MODEL` keys in
  `.claude/settings.local.json`, and the `/.claude/settings.local.json` line in `.git/info/exclude`

Settings `/setup` may have added to `~/.claude/settings.json`, which are yours to keep or revert:
`statusLine` (an uninstalled launcher prints nothing, so it is harmless but should go),
`permissions.defaultMode`, `permissions.allow` entries, `effortLevel`, `advisorModel`,
`enabledPlugins`, the two model keys under `env`, and the `security-guidance` tuning keys
(`ENABLE_STOP_REVIEW`, `ENABLE_SECURITY_REMINDER`, `ENABLE_COMMIT_REVIEW`, `ENABLE_PATTERN_RULES`,
`MAX_COMMIT_REVIEWS_PER_SESSION`). `/setup` Part 2 may also have created `CLAUDE.md`, `Docs/` and a
`/Docs/` line in `.gitignore` in your projects; those are your files.

## Troubleshooting

- **Nothing happens after install.** Restart Claude Code. Then run `/my-claude-setup:status`: each
  hook shows `ok` or `MISSING`. Hooks fail open, so a broken one is silent at runtime.
- **"no working Python 3 interpreter found".** None of `python3`, `python` or `py -3` ran. See the
  Windows note under Requirements, or install `jq`.
- **"guard.sh could not parse the hook payload; checks were SKIPPED".** Install `jq` or Python 3.
- **No `[context]` lines.** The status line is not installed, or `statusLine` does not point at
  `~/.claude/statusline.mjs`. Run `/my-claude-setup:setup` Part 1.
- **Status line blank.** Set `STATUSLINE_DEBUG=1` to see the launcher's error.
- **`bad interpreter` or `\r` errors from a hook.** A CRLF checkout. `.gitattributes` pins `*.sh` to
  LF; re-clone with that file in place, or run `git add --renormalize .` and re-checkout.

## Contributing and tests

```bash
bash tests/suite.sh               # everything
bash tests/suite.sh consistency   # one section
bash tests/suite.sh --changed     # sections covering your working-tree changes
```

CI runs the suite on ubuntu-latest and windows-latest, because most of what this plugin guards
against only shows on Windows. Conventions for working on the repo are in `.claude/CLAUDE.md`;
release history is in `CHANGELOG.md`.

## License

MIT, see `LICENSE`.
