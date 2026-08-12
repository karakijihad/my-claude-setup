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
| Node.js | the status line in `assets/statusline.mjs` (optional) | `node --version` |

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
hooks/              hooks.json + 4 hooks and their shared helpers
skills/             9 skills — 7 protocols, plus dependency-auditor and skill-security-auditor
commands/           setup — machine setup (Part 1), project setup (Part 2)
assets/templates/   project CLAUDE.md, session note, doclog, changelog, audit README, Docs skeleton
assets/             statusline.mjs, the status line /setup installs
```

### Hooks

| Hook | Event | What it does |
|-|-|-|
| `session-start.sh` → `.py` → `core.md` | SessionStart | Injects the resident core (its text lives in `core.md`, read by the Python path and re-emitted via jq by the fallback, so there is one copy) — brevity, code discipline, the confirm-first threshold, the fast path, the review-escalation ladder, the plan-first offer — plus the current branch, the Tier-2 reviewer notice, and the one-time onboarding check. Commit subjects were deliberately dropped: they are arbitrary free text injected before the user has asked anything. If no Python is available it falls back to a reduced core rather than emitting nothing |
| `guard.sh` | PreToolUse | Blocks `rm -rf /`, force-push, `reset --hard`, `clean -f`, `checkout -- `, `branch -D` (but not `-d`), `DROP TABLE`/`DROP DATABASE`/`TRUNCATE TABLE`; blocks writes to `.env*` (except `.env.example`, `.sample`, `.template`), lockfiles, and `.git/`; scans the **staged diff** on commit for value-shaped secrets and for credential material — AWS keys, private keys, `ghp_`/`sk-` tokens |
| `post-push.sh` | PostToolUse | After a push that actually landed, and only if the repo has CI config, names the pushed SHA and the provider's check command. Verifies nothing and exits 0 on every path — PostToolUse runs after the call and cannot block it |
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
| `/setup` **Part 1** | Sets up a machine: adds the marketplaces, installs the companion plugins, reports anything installed that isn't in the roster, merges the recommended `settings.json` keys, tunes the companions so their triggers don't double-fire, and installs the status line. Shows a diff, asks first, idempotent |
| `/setup` **Part 2** | Sets up a project: scaffolds `CLAUDE.md` and the `Docs/` tree on a blank slate, or surveys an existing repo and reports before writing. Never rewrites a `CLAUDE.md` you already have; migrates the older seven-folder `Docs/` layout |

## The status line

![The status line: model and effort, session spend, context and cache-hit rate, memory, the active skill, branch and lines edited](assets/statusline.svg)

Three lines. Identity and spend; what the session and the machine are carrying; the repo. `/setup`
installs it and `node` is the only requirement — no `npm install`, no dependencies.

Colour is a signal rather than decoration. Context, cache-hit rate and memory are scaled
green → amber → red, so the bar can be read without parsing a number, and anything that cannot
meaningfully be "bad" stays neutral. The cache ratio **floors rather than rounds**: a healthy
session sits around 99.6%, and rounding that to "100%" would claim a perfect hit that did not
happen.

It shows **effort** but not the model name — Claude Code already prints the model, and a status
line should add what the harness doesn't. Effort is the opposite case: set in `settings.json`,
paid on every message, and surfaced nowhere else. `STATUSLINE_GIT_CHANGES=1` adds a dirty-file
count, at the cost of the one subprocess this script otherwise avoids.

The image above is generated from the script's real ANSI output rather than screenshotted, so it
cannot quietly drift from the code.

## Measured cost

Every hook and the status line are on hot paths, so this plugin's own overhead is the thing most
worth measuring about it. All figures below are **one machine — Windows 11, Node 24, Python
3.12** — and are the median of repeated runs. Treat them as the shape of the problem, not as a
benchmark: Linux and macOS spawn processes several times faster, so the absolute numbers there
are much smaller and the *ratios* are what carry over.

| Path | Fires | Before | After |
|-|-|-|-|
| `guard.sh` | every Bash, Edit, Write | 928 ms | **239 ms** |
| Status line | every render, ~7.7/min | 1665 ms | **106 ms** |
| Status line, per minute of work | — | 12.8 s | **0.85 s** |
| `post-push.sh` | every Bash | 588 ms | **379 ms** |
| `session-start.sh` | once per session | 536 ms | **400 ms** |

Two findings from that profiling are worth stating plainly, because both contradict the obvious
guess:

- **Context was never the problem.** The resident core plus every skill description is ~1.3k
  tokens, well under 1% of a 1M window, and the measured prompt-cache hit rate is 99.6%. The cost
  was **process spawns** — 45–200 ms each on Windows against roughly 5–30 ms elsewhere, so
  anything that shells out pays about ten times what its author expected.
- **The engine, not the logic.** `guard.sh` got 3.9× faster without changing a single rule it
  enforces: six `grep` pipelines and three interpreter calls became bash's own `[[ =~ ]]` and one
  JSON read. The old version spent most of its time discovering it had nothing to do.

The suite is 78 assertions on **ubuntu-latest and windows-latest**. Both platforms deliberately —
the first CI run this repo ever had came back 78/0 on Windows and 77/1 on ubuntu, and that
asymmetry was a real bug: `guard.sh` protected `.env` on one OS and not the other, from an
identical payload, because `basename` only splits on backslashes under MSYS.

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

**Run `/setup` and it installs all of them**, marketplaces included. The command list used to be
repeated here too, which made this file a fifth copy of the roster — and the copy that drifted:
it went on telling people to install two plugins that had already been dropped. The table below
says what each one is *for*; `/setup` is the only place that says how to get it.

Each has **exactly one job**, so no two contend for the same decision. That assignment is the
point — the failure mode isn't tokens, it's several plugins that all think they own "review".

Two were removed for failing that test in the other direction. `code-review` shipped a command
shadowed by Claude Code's own built-in `/code-review`, and `code-simplifier` shipped only an
*agent* — passive, dispatched by nothing, while the routing table called it "opt-in". Neither
could fire, and both sat in the roster unused for over a month. A companion that cannot trigger
is not a companion. The built-in `/code-review` and `/simplify` cover both jobs.

The table, `hooks/core.md`'s companion sentence, `COMPANIONS` in `hooks/onboarding.py`, and
`/setup`'s install block must all name the same set. `tests/suite.sh` asserts that in every
direction — an earlier version checked only one way, which passes happily when a companion is
*dropped* from one surface, the exact drift it existed to catch.

| Plugin | Its one job | Fires when |
|-|-|-|
| `feature-dev` | **Tier 2 reviewer** — `code-reviewer`, the ladder's default. **The one that matters most** | Any real change |
| `trio` | **Tier 3 audit** — Codex reviews read-only through parallel lenses, Claude adjudicates each finding. Also second opinions via `trio-consult` | Auth, secrets, payments, migrations, deletion; >5 files; a release; or reviewer-vs-diff disagreement |
| `superpowers` | **Process** — brainstorming, writing-plans, test-driven-development, verification-before-completion | Larger tasks only — never the fast path |
| `security-guidance` | **Tier 3 security pass** — not a general reviewer | `security-protocol` §9 gate |
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

There is no fourth tree. A project that must deviate from a protocol says so in its own
`CLAUDE.md` — that file is loaded every session, and a folder of overrides is loaded by nobody.
Anything else you want written down, ask what reads it first.

**`Docs/` is gitignored by default** — the whole tree, including subfolders you add later. It
holds working evidence, and some of it is nobody else's business; `CHANGELOG.md` sits at the
repo root because a release note has to reach people who don't have your working copy. Want it
versioned instead? Say so, and the commands write that into your `CLAUDE.md` under a `Docs
policy` heading so a later session doesn't re-add the line.

`/setup` creates this for a new repo and migrates an existing one. See the
`project-docs` skill for line budgets.

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
