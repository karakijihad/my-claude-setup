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
| Python 3 | `session-start` hook, `skill-security-auditor`, and stdin parsing in `guard.sh`/`notify.sh` when `jq` is absent | `python -c "import sys; print(sys.version_info[:2])"` |
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
hooks/              hooks.json + 3 hooks and their shared helpers
skills/             9 skills — 7 protocols, plus dependency-auditor and skill-security-auditor
commands/           setup, bootstrap-project, repo-fix
assets/templates/   project CLAUDE.md, session note, doclog, changelog, audit README, Docs skeleton
assets/             ccstatusline-settings.json, the starting status-line config /setup offers
```

### Hooks

| Hook | Event | What it does |
|-|-|-|
| `session-start.sh` → `.py` → `core.md` | SessionStart | Injects the resident core (its text lives in `core.md`, read by the Python path and re-emitted via jq by the fallback, so there is one copy) — brevity, code discipline, the confirm-first threshold, the fast path, the review-escalation ladder, the plan-first offer — plus the current branch, the Tier-2 reviewer notice, and the one-time onboarding check. Commit subjects were deliberately dropped: they are arbitrary free text injected before the user has asked anything. If no Python is available it falls back to a reduced core rather than emitting nothing |
| `guard.sh` | PreToolUse | Blocks `rm -rf /`, force-push, `reset --hard`, `clean -f`, `checkout -- `, `branch -D` (but not `-d`), `DROP TABLE`/`DROP DATABASE`/`TRUNCATE TABLE`; blocks writes to `.env*` (except `.env.example`, `.sample`, `.template`), lockfiles, and `.git/`; scans the **staged diff** on commit for value-shaped secrets and for credential material — AWS keys, private keys, `ghp_`/`sk-` tokens |
| `notify.sh` | Notification | Desktop notification — notify-send, osascript, or PowerShell |

`guard.sh` is one script doing what three used to. The old ones each spawned a shell and a JSON
parse on *every* Bash call just to determine they had nothing to do.

Two hooks were deliberately removed: a pre-commit test runner that cost up to 120s per commit
and discarded its own output, and a formatter that ran `npx prettier` after every write —
rewriting Markdown as it was authored and desyncing editor state.

Hooks that need event fields parse stdin with `lib-parse.sh` (jq if present, otherwise a Python
located by `py.sh`), so they work without `jq` installed.

A third hook was removed in 1.4.0: a `UserPromptSubmit` hook that re-stated the brevity rule on
every single turn. Brevity is already line 1 of `core.md`; re-injecting it each turn paid for the
same instruction indefinitely to fix a compliance decay that current models don't exhibit.

### Skills

Invoke by name, or let the description trigger them.

| Skill | Covers |
|-|-|
| `security-protocol` | Threat model, input validation, auth, data, API, dependencies, AI/agent security — 10 references |
| `testing-protocol` | When tests are required, quality rules, coverage, verification levels |
| `git-protocol` | Conventional commits, safety rules, PR process — and asks before branching rather than assuming |
| `agent-protocol` | Delegation, structured task reports, sub-agent context budgeting, orchestration |
| `feedback-protocol` | Turning corrections into permanent rules |
| `planning-protocol` | When phased work earns a plan file, and what the file needs to survive a context reset |
| `project-docs` | The `Docs/` convention, line budgets, templates |
| `dependency-auditor` | Vulnerability scanning, license compliance, upgrade planning via each ecosystem's native tools |
| `skill-security-auditor` | Static audit of a skill before you install it |

`security-protocol` §7 (AI/agent security) is the one to read before adding an MCP server or
installing someone else's skill — prompt injection, tool authority, supply chain, transcript
hygiene.

### Commands

| Command | Does |
|-|-|
| `/setup` | Merges the recommended `settings.json` keys. Shows a diff, asks first, idempotent. Also offers `ccstatusline` and the status-line config in `assets/` |
| `/bootstrap-project` | Scaffolds a project `CLAUDE.md` and the `Docs/` tree — assumes a blank slate |
| `/repo-fix` | Surveys an **existing** repo against these conventions and reports before writing. Never rewrites a `CLAUDE.md` you already have; migrates the older seven-folder `Docs/` layout |

## The review ladder

Every code-modifying task ends on one of three rungs, and skipping one needs a stated reason.
The variable isn't effort — it's **independence**.

| Tier | Reviewer | Independence | Fires when |
|-|-|-|-|
| **1** | Claude re-reads its own diff | None — same context, same assumptions | One file, <50 lines, nothing sensitive |
| **2** | `feature-dev:code-reviewer`, a fresh agent | Fresh context, same model — it never saw the conversation, so it can't inherit an assumption | **Default** for any real change |
| **3** | `trio` — Codex audits, Claude adjudicates | Fresh context **and** a different vendor | Auth, secrets, payments, migrations, deletion; >5 files; a release; a cross-module refactor; a new dependency or MCP surface; or reviewer-vs-diff disagreement |

Tier 3 exists because a second Claude shares the first Claude's blind spots and a different
model does not. Read-only work and pure-doc edits are exempt from all three.

**Tier 2 is announced at session start.** `trio` ships its own SessionStart hook and
`superpowers` injects a block, so both are in context whether or not anything asks for them.
`feature-dev` ships *agents*, and an agent is passive — nothing dispatches one unless something
decides to. That made the default rung the one that could fail silently: no error, just a review
that quietly didn't happen. So `session-start.py` names it every session — and when feature-dev
isn't enabled, says *that* instead, because a review that never happened must not read like one
that did.

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

Each has **exactly one job**, so no two contend for the same decision. That assignment is the
point — the failure mode isn't tokens, it's four plugins that all think they own "review".

| Plugin | Its one job | Fires when |
|-|-|-|
| `feature-dev` | **Tier 2 reviewer** — `code-reviewer`, the ladder's default. **The one that matters most** | Any real change |
| `trio` | **Tier 3 audit** — Codex reviews read-only through parallel lenses, Claude adjudicates each finding. Also second opinions via `trio-consult` | Auth, secrets, payments, migrations, deletion; >5 files; a release; or reviewer-vs-diff disagreement |
| `superpowers` | **Process** — brainstorming, writing-plans, test-driven-development, verification-before-completion | Larger tasks only — never the fast path |
| `security-guidance` | **Tier 3 security pass** — not a general reviewer | `security-protocol` §9 gate |
| `code-review` | **GitHub PR review** — a different artifact from a working diff | An actual PR exists |
| `code-simplifier` | **Opt-in cleanup**, run before the reviewer sees the code | You ask, on larger tasks |
| `context7` | **Unfamiliar or version-sensitive APIs** — not settled ones | Reaching for an API you can't verify from the repo |
| `playwright` | **Changed interactive or rendering behaviour** | Not every CSS tweak |

## Per-project docs

Append-only, newest first. The rule is **only what git cannot reconstruct** — it already records
what changed and when, so anything restating that is written once, read often, stale in a month,
and misleading once stale.

```
Docs/
├── Decisions/YYYY-MM-DD.md       why, and what was rejected
├── Audit/{agent}/YYYY-MM-DD/     findings and their adjudication
└── Plan/                         in-flight only; deleted when the work lands
CHANGELOG.md                      repo root, committed, grouped by release
```

Three things pass that test. `Decisions/` holds the road **not** taken — a diff shows the road
taken, and the rejected option is what gets re-litigated six months later. `Audit/` keeps
findings *and* their refutations, which is the half a commit never preserves; it is evidence,
never a decision by itself. `Plan/` is the only forward-looking tree and exists so work survives
a context reset.

Cut in 1.5.0: `Sessions/` and `Docs/Changelog/` — a daily work log is `git log --since=yesterday`
with worse fidelity. Still documented but no longer scaffolded: `Docs/Protocols/` for a genuine
project override, and `Docs/Logs/CODEMAP.md`, which should be generated on demand because a
CODEMAP that lags a rename is worse than none — it gets believed.

`/bootstrap-project` creates this for a new repo; `/repo-fix` migrates an existing one. Projects
still using the older `Doclog/` name keep it — it's the same tree, and renaming an append-only
history buys nothing. See the `project-docs` skill for line budgets.

## Downloading

1. `/plugin marketplace add karakijihad/my-claude-setup` and install.
2. Restart Claude Code — the hooks and commands only register once the plugin loads.
3. `/setup`.

The first-run check reports whatever the old install left behind — `~/.claude/CLAUDE.md`, a
linked `Docs/`, `hooks/` or `Templates/`, and any hook still naming this config's removed
scripts — and offers to remove them, listing each path first. It never touches your
`settings.json`, and only links into an old clone are candidates; real files are reported and
left alone.

## Updating

```
/plugin update my-claude-setup@my-claude-setup
```

## License

MIT
