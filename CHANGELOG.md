# Changelog

All notable changes to this plugin. Newest release first. Releases before 1.3.0 predate this
file — see `git log --grep="bump to"`.

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
  `git log --since=yesterday` with worse fidelity. `Logs/CODEMAP.md` and `Docs/Protocols/`
  remain documented but are no longer scaffolded; create them the day they're needed.
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
