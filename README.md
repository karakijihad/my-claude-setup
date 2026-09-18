# my-claude-setup

A rail for how Claude Code works, packaged as a plugin.

It doesn't add capabilities — it decides how the ones you have get used: when to plan, when to
fan out agents, which companion plugin owns which decision, what a review must clear before the
work is called done, and where a project's documents live. A small resident core, six protocol
skills that load on demand, six hooks, two agents, one command.

```
/plugin marketplace add karakijihad/my-claude-setup
/plugin install my-claude-setup@my-claude-setup
```

Then **restart Claude Code** — installing a plugin mid-session fires no `SessionStart`, so
nothing happens until you do. On the first sessions after install it checks what is actually
missing — companion plugins, recommended settings, leftovers from an older install — and offers
to walk you through it. It runs nothing without your agreement and goes quiet once there is
nothing to fix.

The notice appears for up to three sessions rather than one: `SessionStart` context arrives with
no user turn attached, so a notice spent on a session you closed immediately would be lost for
good. Tracked by `~/.claude/.my-claude-setup-onboarded`; delete it to see the notice again.

## Prerequisites

| Requirement | Needed by | Check |
|-|-|-|
| Git | everything | `git --version` |
| Python 3 | the SessionStart hook, and stdin parsing in `guard.sh` when `jq` is absent | `python -c "import sys; print(sys.version_info[:2])"` |
| Node.js | the status line (optional) | `node --version` |

Every Python entry point runs through `hooks/py.sh`, which *executes* each of `python3`,
`python` and `py -3` and uses the first that actually works.

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

To make `python3` work for your own shell use:

```powershell
$PY = "$env:LOCALAPPDATA\Programs\Python\Python313"
Copy-Item "$PY\python.exe" "$PY\python3.exe"
```

Exit code 1618 during install means another MSI holds the installer mutex. Don't kill
`msiexec`; reboot and retry.

</details>

## What's inside

```
hooks/              hooks.json + 5 hooks and their shared helpers
skills/             6 protocol skills, loaded on demand
agents/             worker and advisor — delegated work and consults, both effort high
commands/           setup — machine setup (Part 1), project setup (Part 2)
assets/             statusline.mjs and the document templates
```

### Hooks

| Hook | Event | What it does |
|-|-|-|
| `session-start.sh` → `.py` → `core.md` | SessionStart | Injects the resident core — brevity, code discipline, the fast path, the review ladder, the fan-out rule, the companion roster. Its text lives in `core.md`, so the no-Python fallback emits the same bytes rather than a second copy that drifts. Adds the branch, the Tier-2 reviewer notice, and the one-time onboarding check |
| `guard.sh` | PreToolUse | Blocks `rm -rf /`, force-push, `reset --hard`, `clean -f`, `checkout -- `, `branch -D` (but not `-d`), `DROP TABLE`/`DROP DATABASE`/`TRUNCATE TABLE`, and the PowerShell equivalents; blocks writes to `.env*` (except `.env.example`), lockfiles and `.git/`; scans the **staged diff** on commit for value-shaped secrets and credential material |
| `budget.sh` | PostToolUse | Warns when a project doc outgrows its line budget. Ratcheted: it speaks on the first crossing and again only when an edit makes the overage worse, so the edits that fix the file never nag. Never blocks |
| `post-push.sh` | PostToolUse | After a push, names the SHA and points at the repo's own CI command in its `CLAUDE.md`. It doesn't detect providers and doesn't claim the push landed — a confident wrong pointer is worse than silence. Exits 0 on every path |
| `context-watch.sh` | PostToolBatch | Reads the context fill `statusline.mjs` writes to a state file each render — no hook payload carries it — and injects a `[context] 350k/1.0M (35%)` line once per 5%-of-window crossing. Past the handoff budget (`$CLAUDE_HANDOFF_BUDGET`, else 60% of the window) it says to write the handoff instead. Never blocks |

### Skills

| Skill | Covers |
|-|-|
| `project-docs` | The `Docs/` convention, line budgets, the handoff, templates |
| `planning-protocol` | When phased work earns a plan file, and why a plan is a guide rather than a specification |
| `agent-protocol` | The brief a sub-agent gets and the report it owes back |
| `testing-protocol` | Where the fast path ends and TDD takes over, and what earns a test at all |
| `git-protocol` | Don't branch unless asked, what to confirm first, and checking CI by SHA |
| `security-protocol` | Escalation, and the agent/MCP tool-authority rules a code reviewer won't cover. The security expertise itself belongs to the `security-guidance` companion |

### Commands

| | |
|-|-|
| `/setup` **Part 1** | Sets up a machine: adds the marketplaces, installs the companion plugins, merges the recommended `settings.json` keys, tunes the companions so their triggers don't double-fire, installs the status line. Shows a diff, asks first, idempotent |
| `/setup` **Part 2** | Sets up a project: scaffolds `CLAUDE.md` and the `Docs/` tree, or surveys an existing repo and reports before writing. Never rewrites a `CLAUDE.md` you already have |

## The status line

![The status line: model and effort, machine memory, session spend, context, session input and output tokens, cache-hit rate, the active skill, branch and lines edited](assets/statusline.svg)

Three lines. Identity and spend; what the session and the machine are carrying; the repo.
`/setup` installs it and `node` is the only requirement.

Colour is a signal rather than decoration: context, cache-hit rate and memory scale green →
amber → red, and anything that cannot meaningfully be "bad" stays neutral. The cache ratio
**floors rather than rounds** — a healthy session sits around 99.6%, and rounding that to "100%"
would claim a perfect hit that did not happen.

It shows **effort** but not the model name: Claude Code already prints the model, and effort is
set in `settings.json`, paid on every message, and surfaced nowhere else. The image above is
generated from the script's real ANSI output, so it cannot quietly drift from the code.

It also writes the session's context fill to a state file, which is the only way
`context-watch.sh` can know it — no hook payload carries `context_window`.

## The review ladder

Every code-modifying task ends on one of three rungs, and skipping one needs a stated reason.
The variable isn't effort — it's **independence**.

| Tier | Reviewer | Independence | Fires when |
|-|-|-|-|
| **1** | Claude re-reads its own diff | None — same context, same assumptions | One file, <50 lines, nothing sensitive |
| **2** | `feature-dev:code-reviewer`, a fresh agent | Fresh context, same model — it never saw the conversation, so it can't inherit an assumption | **Default** for any real change |
| **3** | `trio` — Codex audits, Claude adjudicates | Fresh context **and** a different vendor | Auth, secrets, payments, migrations, deletion; >5 files; a release; or reviewer-vs-diff disagreement |

Tier 3 exists because a second Claude shares the first Claude's blind spots and a different
model does not. Read-only work and pure-doc edits are exempt from all three.

**Tier 2 is announced at session start.** `trio` and `superpowers` inject their own context;
`feature-dev` ships *agents*, and an agent is passive — nothing dispatches one unless something
decides to. That made the default rung the one that could fail silently. So `session-start.py`
names it every session, and when feature-dev isn't enabled says *that* instead, because a review
that never happened must not read like one that did.

## Companion plugins

The protocols name these by default. Nothing hard-fails without them — Claude is told to say so
and fall back to the manual equivalent — but the workflow is thinner. **Run `/setup` and it
installs all of them**, marketplaces included.

Each has **exactly one job**, so no two contend for the same decision. That assignment is the
point: the failure mode isn't tokens, it's several plugins that all think they own "review".

| Plugin | Its one job | Fires when |
|-|-|-|
| `feature-dev` | **Tier 2 reviewer** — `code-reviewer`, the ladder's default. **The one that matters most** | Any real change |
| `trio` | **Tier 3 audit** — Codex reviews read-only through parallel lenses, Claude adjudicates each finding. `trio-consult` is the other job: advice before a choice, never a review of finished work | Auth, secrets, payments, migrations, deletion; >5 files; a release; or reviewer-vs-diff disagreement |
| `superpowers` | **Process** — brainstorming, writing-plans, test-driven-development, verification-before-completion | Larger tasks only — never the fast path |
| `security-guidance` | **Tier 3 security pass, and the security expertise this plugin deliberately doesn't carry** | Auth, secrets, credentials, untrusted input |
| `context7` | **Unfamiliar or version-sensitive APIs** — not settled ones | Reaching for an API you can't verify from the repo |
| `playwright` | **Changed interactive or rendering behaviour** | Not every CSS tweak |

That table, `hooks/core.md`'s companion sentence, `COMPANIONS` in `hooks/onboarding.py` and
`/setup`'s install block must all name the same set. `tests/suite.sh` asserts it in every
direction — an earlier version checked only one way, which passes happily when a companion is
*dropped* from one surface, the exact drift it existed to catch.

## Per-project docs

`Docs/` holds what git cannot reconstruct: why a decision was made and what was rejected, what
an audit found and how it was adjudicated, an in-flight plan, and a handoff for when a session
runs out of context. It is **gitignored by default** — working evidence, not a deliverable — and
committing it instead is a one-line note in the project's `CLAUDE.md`. Full convention in
`skills/project-docs`.

## Tests

```bash
bash tests/suite.sh            # everything
bash tests/suite.sh guard      # one section
```

CI runs the suite on **ubuntu-latest and windows-latest**. Both deliberately: this plugin exists
largely because Windows breaks Unix assumptions — a Store-stub `python3`, a CRLF checkout, a BOM
hiding a config — and every one of those is invisible on ubuntu. The first CI run this repo ever
had came back green on Windows and red on ubuntu, and the asymmetry was real: `guard.sh`
protected `.env` on one OS and not the other, from an identical payload.

What earns a case is in `skills/testing-protocol` — safety keeps every failure mechanism,
contracts get one case per path, advisory gets four. A suite that outgrows the thing it tests
stops being read, and a suite nobody reads is not coverage.

## Updating

`claude plugin update my-claude-setup`, then restart. The next session reports what changed and
repairs anything the update broke — chiefly the status line, whose `settings.json` entry points
at a stable path rather than the version-pinned plugin directory, because that path fails
*silently* when it goes stale.

## License

MIT
