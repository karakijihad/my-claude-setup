---
description: Set up a machine or a project for this plugin. Use on a new PC to install the companion marketplaces, plugins and settings, or inside a repo to scaffold its CLAUDE.md and Docs/ convention. Surveys before it writes either way.
---

The one command this plugin ships. It has two halves and they run at different times:

- **Part 1 — machine.** Once per PC. Installs the companions and writes `settings.json`.
- **Part 2 — project.** Once per repo. Writes that project's `CLAUDE.md` and `Docs/` tree.

Decide which the user wants before doing anything. A bare `/setup` on a fresh machine means
Part 1; a bare `/setup` inside a repo that already has `~/.claude/settings.json` configured
means Part 2. When it is genuinely ambiguous, ask — don't run both.

**This plugin is opinionated on purpose.** It carries its author's plugin set, keybind-level
preferences and companion tuning, and it writes them without pretending to be neutral. That is
the point: install it on a new machine and the machine works the way the last one did. Anyone
else installing it is adopting those choices knowingly. What it must *never* do is write them
silently — every part below shows a diff and asks first.

---

# Part 1 — This machine

## 1.1 Marketplaces

`claude-plugins-official` is built in. Add the other two, skipping any already present
(`claude plugin marketplace list`):

```bash
claude plugin marketplace add karakijihad/trio-cc
claude plugin marketplace add karakijihad/my-claude-setup
```

`openai/codex-plugin-cc` is deliberately **not** added. Trio drives the `codex` CLI directly;
the plugin is a separate thing and is not part of this setup.

## 1.2 Companion plugins

Install each, skipping any already installed (`claude plugin list`).

Two groups, and the split is the point.

**Companions** — `core.md` routes work to these by name, one job each. That list and this one
must agree, and `tests/suite.sh` asserts they do, so drift fails the suite instead of
shipping.

```bash
claude plugin install feature-dev@claude-plugins-official       # the Tier-2 reviewer
claude plugin install trio@trio-cc                              # Tier-3 audit, second opinions
claude plugin install security-guidance@claude-plugins-official # Tier-3 security pass
claude plugin install superpowers@claude-plugins-official       # process on larger tasks only
claude plugin install context7@claude-plugins-official          # version-sensitive APIs
claude plugin install playwright@claude-plugins-official        # interactive/rendering changes
```

**Tools** — useful, but they contend for no decision, so `core.md` neither names them nor needs
to. Nothing routes to them; the operator invokes them directly. Add or drop freely.

```bash
claude plugin install claude-md-management@claude-plugins-official
claude plugin install frontend-design@claude-plugins-official
claude plugin install skill-creator@claude-plugins-official
claude plugin install ralph-loop@claude-plugins-official
claude plugin install firecrawl@claude-plugins-official
```

Report anything that fails rather than continuing silently. A companion that failed to install
is worse than one that was never in the list, because `core.md` will keep routing work to it.

## 1.3 What's installed that isn't in the roster

Report it, and stop there. List every installed plugin that is not in 1.2, one per line, with a
one-line note on what it does if you can tell. Then say that removing any of them is
`claude plugin uninstall <name>`, and move on to 1.4.

**This command does not remove anything.** An earlier version offered to, behind a batched
yes/no with reassurances about reversibility — and the reassurance turned out to be false for
one class of item, which is how a convenience became the only irreversible step in a command
whose whole premise is that it is safe to run. Removing the feature removed the problem. A user
who wants a plugin gone can run one command; they do not need this one to do it for them, and
the cost of getting it wrong on someone else's machine is not worth the keystroke it saves.

## 1.4 `settings.json`

Read `~/.claude/settings.json` (`{}` if absent). **Only add or change the keys below.** Never
remove or reorder anything else. Show a diff, ask, then write. If nothing would change, say so
and stop — this command is idempotent.

| Key | Value | Why |
|-|-|-|
| `env.CLAUDE_CODE_SUBAGENT_MODEL` | `"sonnet"` | Sub-agents run faster and cheaper on Sonnet |
| `permissions.defaultMode` | `"auto"` | |
| `permissions.allow` | union with `["Bash(git:*)", "Bash(ls:*)", "Bash(npm:*)", "Bash(pnpm:*)", "Bash(python:*)", "Bash(xargs grep:*)"]` | Fewer prompts on what a normal session runs constantly. **Read the note below.** |
| `effortLevel` | `"high"` | |
| `enabledPlugins` | every plugin from 1.2, `true` | |

Do **not** set `model` — leave the user's choice alone.

Do **not** add `MAX_THINKING_TOKENS`, `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`, or
`CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING`. They have no effect on Claude 5 models; shipping them
teaches people to cargo-cult dead config.

Do **not** add a `hooks` block. This plugin's hooks live in its own `hooks/hooks.json` and are
active as soon as it is enabled. A hook copied into `settings.json` would run twice.

### About `Bash(npm:*)` and `Bash(python:*)`

Be straight about these two rather than presenting the list as "least-privilege". `npm run
<anything>` executes whatever the project's `package.json` defines, and `python:*` runs
arbitrary code — allowlisting them is a real widening, worth most in exactly the repo where it
is riskiest: one whose scripts you did not write.

They are in the default because a Node or Python session prompts constantly without them, and
prompt fatigue causes worse decisions than the widening does. That is a judgment, not a security
argument. If the user works mainly in untrusted repos, tell them to drop these two and keep the
rest — the merge is per-key. `guard.sh` blocks destructive commands either way; this list
controls confirmation prompts, not the safety hooks.

## 1.5 Companion tuning — stop the double-fire

`security-guidance` runs four separate automatic checks, and two of them re-do work `core.md`
already routes. Left at their defaults you get reviewed twice for every turn: once by the review
ladder in `core.md` line "Review escalates with stakes", and again by the plugin's own Stop
review, which uses `asyncRewake` and so re-invokes the model with extra instructions.

Keeping the plugin and turning off its duplicates is strictly better than disabling it. Merge
into `env` (all values are strings):

| Key | Value | Why |
|-|-|-|
| `ENABLE_STOP_REVIEW` | `"0"` | The duplicate. `core.md` already ends every code task on a review rung |
| `ENABLE_SECURITY_REMINDER` | `"0"` | Injects a reminder every prompt; `core.md` already routes to `security-protocol` |
| `ENABLE_COMMIT_REVIEW` | `"1"` | **Keep.** An LLM review of the real staged diff, at the moment it matters. Nothing else here does this |
| `ENABLE_PATTERN_RULES` | `"1"` | **Keep.** Pure regex, no model call. Catches what `guard.sh` doesn't |
| `MAX_COMMIT_REVIEWS_PER_SESSION` | `"5"` | Bounds the one that stays |

Explain the trade before writing: the user keeps the two checks nothing else duplicates and
drops the two that fire on top of the core. If they'd rather keep everything on, skip this
section — it is a preference, not a correctness fix.

## 1.6 Status line

Three lines: model and effort, then what the session has spent; context against the real window,
cache hit rate, memory and the skill in play; then branch and lines written. No dependencies, no
`npm install` and no subprocess — a plain node script that ships with the plugin.
`STATUSLINE_GIT_CHANGES=1` adds a dirty-file count at the cost of one `git` spawn per render.

Two steps, and the first is what makes it survive updates:

1. Copy `${CLAUDE_PLUGIN_ROOT}/assets/statusline-launcher.mjs` to `~/.claude/statusline.mjs`.
2. Set `statusLine` to
   `{"type": "command", "command": "node \"<home>/.claude/statusline.mjs\"", "padding": 0}`,
   with `<home>` an absolute path using forward slashes.

Never point `statusLine` inside the plugin's own directory. That path carries the version, so it
stops matching on the next release — and it fails *quietly*, because Claude Code keeps every
previously installed version on disk: the stale path still resolves, still runs, and the bar goes
on rendering from a release nobody is using. The launcher is one file whose only job is to read
`installed_plugins.json` and hand off to whichever release is current.

**After this, updates run themselves.** `hooks/selfheal.py` fires on the first session after the
installed version moves. It diffs the outgoing release against the incoming one, repairs the
status-line wiring, deletes the superseded cached releases, and then hands this command back to
the session to reconcile sections 1.1–1.5 against the machine. So a user who never types `/setup`
again still ends up with the marketplaces, roster, settings and tuning of the release they are
running — and a summary of what changed. On sessions where the version has not moved it does
nothing and says nothing.

---

# Part 2 — This project

Confirm the working directory is the project root. If it looks wrong, ask before writing.

Then pick a mode by what's actually there. **Blank slate** — no `CLAUDE.md`, no `Docs/`, little
or no history: go to 2.1. **Existing repo** — anything else: go to 2.2, which surveys first and
writes nothing until the user agrees. When in doubt, survey; it is read-only.

## 2.1 Blank slate

1. Copy `${CLAUDE_PLUGIN_ROOT}/assets/templates/project-CLAUDE.md` to `./CLAUDE.md`. If one
   exists, leave it alone and say so — never overwrite a project's existing instructions.
2. Copy `${CLAUDE_PLUGIN_ROOT}/assets/templates/Docs-skeleton/` to `./Docs/`. If it exists,
   report which of `Decisions/ Audit/ Plan/` are missing and offer only those. A project using
   the older `Doclog/` name keeps it — don't rename an append-only history. Those three are the
   whole convention; never invent a fourth folder. A project-specific deviation goes in that
   project's `CLAUDE.md`, which is loaded every session.
3. If `./CHANGELOG.md` does not exist, offer to add it from `changelog-entry.md`. It lives at the
   **repo root** and is committed — a changelog is read by people without your working copy.
4. **Make `Docs/` local** — see 2.3.
5. **Settle CI** — see 2.4.
6. Fill in what you can read from the repo: name and one-line purpose, stack, the real commands
   from `package.json` / `pyproject.toml` / `Makefile`, key directories. Leave `Gotchas` to the
   user — you can't know those yet.
7. Report what you created and what still needs their input.

## 2.2 Existing repo

### Survey — read-only, no writes in this step

| Check | Looking for |
|-|-|
| `CLAUDE.md` | Present at the root? Does it cover purpose, stack, key files, commands, gotchas? |
| `Docs/` | Which of `Decisions/ Audit/ Plan/` exist |
| Old layout | `Doclog/`, `Sessions/`, `Docs/Changelog/`, `Logs/`, `Protocols/` |
| `CHANGELOG.md` | At the **repo root**, committed |
| `.gitignore` | Covers `.env*`; whether `/Docs/` is ignored; whether `git ls-files -- Docs` shows tracked files; whether a `Docs policy` section in `CLAUDE.md` opts out |
| `.env.example` | Exists if the project reads env vars — `security-protocol` §04 requires it |
| CI | Any of `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `azure-pipelines.yml`, `.circleci/config.yml`, `.travis.yml`, `bitbucket-pipelines.yml`, `appveyor.yml`, `.buildkite/`; and whether `CLAUDE.md` records it under `## CI` |
| Stale plans | Anything in `Docs/Plan/` whose work already landed |

Then **one table: finding · proposed action · risk**, and stop and ask. Do not batch the writes
with the survey — the point of this half is that the user sees the list before anything moves.

### Apply what was agreed

- **Missing `CLAUDE.md`** → template, then fill in what the repo tells you, as in 2.1 step 6.
- **Existing `CLAUDE.md`** → **never rewrite it.** Name the sections it lacks, show the exact
  text you'd append, let the user accept per section. A project's instructions are theirs.
- **Missing `Docs/` trees** → add only the missing ones. Three is the whole convention; don't
  add a fourth because the repo happens to have one.
- **`Logs/` or `Protocols/`** → leave them exactly as they are and don't recreate them
  elsewhere. `Protocols/` was dropped because nothing ever loaded it: a project deviation
  belongs in `CLAUDE.md`, which *is* loaded. If it holds real content, offer to move it there —
  don't delete someone's writing.
- **`Doclog/`** → leave the name alone. Same tree as `Decisions/`, older name. Say it's
  recognised and move on.
- **`Sessions/`** → don't delete it. Report how many files it holds and say the convention
  dropped it because `git log` covers the same ground. Removing it is the user's call.
- **`Docs/Changelog/`** → offer to consolidate into a root `CHANGELOG.md` grouped by release,
  using `changelog-entry.md`. Keep the originals until the user confirms the merge reads right.
- **Stale plan files** → list them, propose deletion, delete nothing unprompted.

## 2.3 Making `Docs/` local

`Docs/` is gitignored by default — the whole tree, including subfolders added later — because it
holds working evidence, some of it private. On an existing repo this is a *decision point*, not
a gap: present it as a choice.

- If `./CLAUDE.md` already has a `Docs policy` section, **stop** and say so. That section exists
  precisely to stop a later session re-adding the line.
- **Keep it versioned** → change nothing, and append a `Docs policy` section to `CLAUDE.md`
  saying so. Without that, the next session re-adds the line.
- **Local from here on** → append to `./.gitignore` (creating it if absent):
  ```gitignore
  # Project docs — local by default, whole tree including subfolders added later
  /Docs/
  ```
  Anchored, because bare `Docs/` also matches a nested `packages/*/Docs/`.
- **Lowercase `docs/` present** → run `git check-ignore -v docs/<some-file>` afterwards.
  `core.ignorecase=true` is the default on Windows and macOS, so `/Docs/` matches `docs/` too
  and anchoring does **not** prevent it. A published docs site wins that collision: don't add
  the line, and record why in `CLAUDE.md`.
- **Files already tracked under `Docs/`** → say plainly that the ignore line alone changes
  nothing for them, that `git rm --cached -r -- Docs/` is what untracks them, and that its next
  push **removes them from the remote**. Run it only on an explicit yes. And if the worry is
  that something private was already pushed: this is not a remediation. It is in history and in
  every clone — that needs rotation and a deliberate history rewrite, outside this command.

## 2.4 Settling CI

Record the answer in `./CLAUDE.md` under `## CI`. Look for the files listed in the survey table.
Found → record provider, trigger, the commands it runs, and the check command. None → ask once
whether the project wants CI and record either answer; `none, confirmed <today>` is what stops a
later session re-asking, and what keeps `post-push.sh` quiet.

**Never write a workflow file unless asked.** This command scaffolds docs.

---

## Closing

Report files created, files appended to, and anything deliberately left alone with the reason.
If the machine or repo was already compliant, say exactly that in one line rather than inventing
work.

**Never** commit, and never touch `.git/`, `.env`, or a lockfile.

The global protocols cover security, testing, git, delegation, and context. A project's
`CLAUDE.md` should carry only what is specific to that repo: architecture, key files, stack,
commands, environment, and gotchas.
