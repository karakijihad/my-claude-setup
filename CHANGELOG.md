# Changelog

All notable changes to this plugin. Newest release first. Releases before 1.3.0 predate this
file — see `git log --grep="bump to"`.

---

## [1.8.0] — 2026-08-12

Driven by a profiling pass rather than a feature idea: sessions had grown slow to launch and
laggy to type in, and the assumption that this was context bloat turned out to be wrong. Resident
context is ~1.3k tokens, well under 1% of the window, and the measured cache hit rate is 99.6%.
The cost was entirely **process spawns** — which on Windows run 90-200ms each, against roughly
5-30ms elsewhere, so anything that shells out pays about ten times what its author expected.

### Changed

- **`guard.sh` no longer shells out to decide it has nothing to do.** It ran six `grep`
  pipelines and three interpreter calls on every Bash tool call, which measured ~930ms on a
  plain `git status`. The patterns are unchanged; the engine is now bash's own `[[ =~ ]]`, and
  the three JSON reads collapsed into one `parse_all`. **655ms → 287ms**, all 54 assertions
  still green. The greps in the secret-scan branch stayed: that path only runs on a commit,
  already pays for a `git diff`, and scanning a whole diff line-by-line in bash would be slower.
- **`lib-parse.sh` gained `parse_all`**, which returns command, file path and notebook path from
  a single call. NUL-delimited and read through a process substitution, because a bash variable
  cannot hold a NUL and `$(...)` would eat the delimiters — tabs and newlines survive, which
  matters since a heredoc in `tool_input.command` is ordinary. `parse_field` is untouched for the
  hooks that want one field.
- **`commands/` is one command.** `setup`, `bootstrap-project` and `repo-fix` became a single
  `/setup` with two halves: Part 1 sets up a machine, Part 2 sets up a project. They were always
  three doors into the same convention, and the split meant a new machine needed someone to
  remember which door to use in which order.

### Added

- **`assets/statusline.mjs`** — a status line in three. Line 1 is the main thread, point-in-time:
  effort level, context used against the model's real window, cache hit ratio, branch. Line 2 is
  the sub-agent lane, cumulative: calls and their token usage. Line 3 is what the session has
  spent, across both lanes. Point-in-time and cumulative are different measures on purpose — you
  steer the main thread by how full it is now, and judge delegation by what it has cost in total.
  It prints no model name: Claude Code shows that itself, and a status line should add what the
  harness doesn't. Effort is the opposite case — set in settings, paid on every message, surfaced
  nowhere else. No dependencies, no `git` subprocess, every failure degrades to a shorter line.
  The cache ratio floors rather than rounds: a healthy session sits at 99.6%, and rounding that
  to "100%" claims a perfect hit that did not happen.
- **`/setup` Part 1 now installs the companions**, not just settings keys: it adds the
  marketplaces, installs each plugin in the roster, and writes `enabledPlugins`. A plugin
  carrying its author's opinions is the point of this one; what it must never do is write them
  silently, so every step shows a diff and asks.
- **A reconcile step**, which is what makes a second machine converge rather than accumulate. It
  lists installed plugins that aren't in the roster alongside `claude plugin prune --dry-run`,
  then asks **once** over the whole list. Never defaults to yes, never removes anything outside
  the list it showed, and says up front that every removal is one `install` away.
- **Companion tuning** in `/setup`. `security-guidance` runs four automatic checks and two of
  them re-do work `core.md` already routes — its Stop review fires on top of the review ladder,
  using `asyncRewake`, so every turn got reviewed twice. `ENABLE_STOP_REVIEW=0` and
  `ENABLE_SECURITY_REMINDER=0` drop the duplicates; `ENABLE_COMMIT_REVIEW` and
  `ENABLE_PATTERN_RULES` stay, because nothing else does what those two do. Keeping a plugin and
  turning off its duplicates beats disabling it.

### Removed

- **`ccstatusline`**, and the `assets/ccstatusline-settings.json` that configured it. It is an
  Ink/React application and boots React even in hook mode: 1665ms per render with the shipped
  four-line config, and still 1189ms stripped to two fields, against 148ms for the replacement.
  Claude Code re-runs the status line as the session updates, so that sat on the render path and
  was the measured cause of the lag. `/setup` should be re-run after any upgrade — the status
  line path contains the plugin version, and a stale one renders nothing.

### Fixed

- **Prose that generalised from one person's setup.** The repo is public; rationale that reads
  "this is how two of the author's machines drift apart" is a story, not a reason. Screened every
  shipped `.md` and rewrote four places in general terms — one of which also assumed a real
  person's pronouns.

---

## [1.7.0] — 2026-08-10

### Added

- **`post-push.sh`, a PostToolUse hook — and with it the first rule about CI anywhere.** The word
  appeared nowhere: nothing said to find a repo's CI, run it, or check whether the run passed.
  `git-protocol` ended at the commit, so nothing owned the interval after `git push` — the only
  place CI exists. The hook fires on a push that actually landed and states the obligation at the
  one moment it is cheap to act on. A prompt, not a gate: it verifies nothing and exits 0 on every
  path, since PostToolUse cannot block a call that already ran. Deliberately, the hook is the
  whole mechanism — the prose around it stayed thin.
- **Keynotes only, in four places**: `git-protocol` §6 and one §4 line (if the repo has CI, run
  what it runs *before* pushing — preventing a red run beats detecting one), a `## CI` block in
  `project-CLAUDE.md`, and detection in `/bootstrap-project` and `/repo-fix`. Those two ask
  **once**, at setup, and record either answer — `none, confirmed <date>` included, since an
  unrecorded "no" gets re-asked forever. Nothing volunteers the question mid-task, and no command
  ever writes a workflow file.

### Fixed

- **The false green this nearly shipped with.** `git push` returns before CI creates the run, so
  the obvious `gh run list --branch <b> -L 1` answers with the *previous* commit's run — often
  green, for a commit that isn't yours. Everything keys on the SHA instead
  (`gh run list -c $(git rev-parse HEAD)`; `-c` confirmed in gh 2.94.0). A stale pass is worse
  than no check: it retires the question.
- **Four outcomes that read as success and aren't.** The reminder demands one of six — green,
  red, cancelled, skipped, queued, unavailable — and only green passes. A skipped job ran nothing;
  a check that couldn't run is `unavailable`. Where no CLI exists the hook emits a pointer, not a
  command that would fail, since a failing command reads as "unavailable" and gets waved past.
- **No CI means silence**, and so does a branch still ahead of its upstream — a rejected push must
  not send anyone to read someone else's run. Absence of config isn't absence of CI (external
  Jenkins, hosted checks), which is why that case is the setup commands' question, not a guess.

---

## [1.6.0] — 2026-08-05

### Changed

- **`Docs/` is gitignored by default — the whole tree, subfolders included.** It was already
  this repo's practice, but the plugin only ever said "possibly-gitignored" (`project-docs`) and
  surveyed "whether `Docs/` is deliberately ignored" (`/repo-fix`), which decides nothing. The
  tree holds working evidence and some of it is private, so the rule names the **directory**
  rather than its children — otherwise it protects only the folders someone remembered to list.
  `project-docs` owns the rule; `/bootstrap-project` writes the line, `/repo-fix` offers it as a
  choice, and `Docs-skeleton/README.md` and `project-CLAUDE.md` both state it.
- **The opt-out has a mechanism.** Committing `Docs/` is a legitimate choice, but it is recorded
  in the project's `CLAUDE.md` under a `Docs policy` heading, and both commands read that before
  touching `.gitignore`. A note left inside `Docs/` is loaded by nobody, so without this the
  next session helpfully re-adds the line — the same argument that killed `Protocols/` in 1.5.0.
- **The pattern is root-anchored `/Docs/`**, including this repo's own `.gitignore`. Bare `Docs/`
  also matches a nested `packages/*/Docs/`; a monorepo gets one explicit line per package
  instead. Verified with `git check-ignore -v`, not from memory.

### Fixed

- **Two documented traps around the ignore line.** `.gitignore` does not untrack: files already
  committed under `Docs/` keep going to the remote until `git rm --cached -r -- Docs/`, whose
  next push *deletes them there* — so `/repo-fix` reports it and never runs it unprompted, and
  says plainly that this is not a fix for something already pushed. And `core.ignorecase=true`
  is the default on Windows and macOS, where `/Docs/` matches a lowercase `docs/` as well —
  anchoring does not help — which would silently ignore a published mkdocs or Docusaurus site.

---

## [1.5.0] — 2026-08-05

### Added

- `commands/repo-fix.md` — surveys an **existing** repo against these conventions and reports
  before writing. `/bootstrap-project` assumes a blank slate; this one assumes history.
- `hooks/session-start.py` — a Tier-2 reviewer notice, emitted every session. trio ships its own
  SessionStart hook and superpowers injects a block, but feature-dev ships only *agents*, which
  are passive. That made the ladder's default rung the one that failed silently. The notice is
  conditional: when feature-dev isn't enabled it says so, loudly.
- `hooks/guard.sh` — three patterns enforcing what `security-protocol` already argued in prose:
  a remote script piped into a shell, `git add -f` staging a gitignored file, and a commit that
  skips git's own hooks.
- `CHANGELOG.md` — this file, at the repo root, because that's what the convention now requires.
- A resident brainstorm trigger. `core.md` triggered *planning* but never *brainstorming* —
  it only named it by exclusion on the fast path, so the trigger came solely from superpowers'
  own session injection. The two settle different questions: planning settles order,
  brainstorming settles what is being built at all, and a plan laid over an unsettled
  requirement is a confident plan for the wrong thing that phases make expensive to unwind.

### Changed

- **`core.md` assigns each companion plugin one job and one trigger.** Four of the eight could
  previously each claim "review". feature-dev is Tier 2; trio is Tier 3; superpowers is process
  on larger tasks only; security-guidance is the Tier-3 security pass, not a general reviewer;
  code-review is GitHub PRs; code-simplifier is opt-in and runs before the reviewer; context7 is
  unfamiliar APIs; playwright is changed interactive behaviour.
- **`Docs/` convention cut from seven trees to three** — `Decisions/`, `Audit/`, `Plan/`, plus a
  committed root `CHANGELOG.md`. The test is whether git can already reconstruct it.
  `assets/templates/Docs-skeleton/`, `project-docs`, `/bootstrap-project`, and both templates
  follow. `Doclog/` is recognised as the older name for `Decisions/` and is never renamed.
- **`testing-protocol` and `superpowers:test-driven-development` no longer contradict.** The
  Iron Law admits no exceptions and names skipping it as rationalization; this protocol exempts
  changes under ~50 lines. Both load, so both fired. The boundary is now the review tier.
- `core.md`'s Context7 rule softened from "never from memory" to unfamiliar or version-sensitive
  APIs — the absolute form forced a lookup for settled library calls.
- `security-protocol`'s description halved. Skill descriptions are resident every session, and
  it enumerated ~30 topics its own index already lists.

- **`feedback-protocol` has an exit.** Steps 1–4 only ever added rules; a loop with no removal
  ends as a rule set nobody reads. §5 retires on evidence about the rule itself — superseded,
  obsolete, duplicated, or never once fired — explicitly **not** a one-in-one-out quota, which
  would delete working guardrails to satisfy arithmetic.
- `setup.md` states plainly that `Bash(npm:*)` and `Bash(python:*)` are a real widening rather
  than filing them under "least-privilege". They stay in the default because prompt fatigue
  causes worse decisions than the widening does — but that's a judgment, now labelled as one.

### Fixed

- `feedback-protocol` routed general-behaviour corrections to `hooks/core.md`, which lives in
  the installed plugin — a local edit there is overwritten by the next `/plugin update`, so the
  rule silently evaporated. Those go to the project `CLAUDE.md`; changing the resident core is
  a PR.
- `skill-security-auditor` documented a CI step invoking `python3` directly, the one thing this
  repo's gotchas forbid. A comment excused it for Linux runners, but it doesn't survive being
  copied to `windows-latest`, where it exits 9009 and reports nothing while looking green.

### Removed

- `Docs/Sessions/` and `Docs/Changelog/` from the convention — a daily "what I did" log is
  `git log --since=yesterday` with worse fidelity.
- `Docs/Protocols/` and `Docs/Logs/CODEMAP.md` **entirely**, not merely unscaffolded.
  `Protocols/` was a convention with no mechanism behind it: nothing in the plugin ever read
  that folder, so a project override written there was loaded by nobody while looking like
  governance. Project deviations go in the project's `CLAUDE.md`, which *is* loaded every
  session. Three trees, and no reserved path for a fourth.
- `assets/templates/session-note.md`.
- `dependency-auditor`'s CI snippet and `skill-security-auditor`'s CI/batch snippets — CI
  config belongs in the project, not in a skill. Their command tables stay: `npm audit`,
  `pip-audit`, `govulncheck` and `cargo audit` have been stable for years, and without them
  the skill guesses.

---

## [1.4.0] — 2026-08-05

### Changed

- **Review is a three-rung ladder rather than one unconditional rule.** Own-diff review for a
  small non-sensitive change; a fresh reviewer agent by default; a Tier-3 Codex audit when the
  change touches auth, secrets, payments, migrations or deletion, spans more than five files, is
  being released, or when the reviewer and the diff disagree. Previously every code-modifying
  task ended with a reviewer agent — including the fast path, which spawned a full agent to
  review a twelve-line diff.

### Removed

- The `UserPromptSubmit` brevity hook. Brevity is line 1 of `core.md`; re-injecting it every
  turn paid for the same instruction indefinitely, to correct a compliance decay current models
  don't exhibit.

---

## [1.3.0] — 2026-08-01

### Added

- `planning-protocol` — offers a plan file before phased work starts.

**Refs** — `git log` for the full history.
