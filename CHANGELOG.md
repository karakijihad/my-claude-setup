# Changelog

All notable changes to this plugin. Newest release first. Releases before 1.3.0 predate this
file — see `git log --grep="bump to"`.

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
