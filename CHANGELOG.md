# Changelog

All notable changes to this plugin. Newest release first. Releases before 1.3.0 predate this
file — see `git log --grep="bump to"`.

---

## [1.12.0] — 2026-08-12

### Fixed

- **The resident core has never loaded.** Not a regression — the wrong shape has been emitted
  for as long as the hook has existed. `session-start.py` printed `{"additionalContext": ...}`
  at the top level. Claude Code reads `hookSpecificOutput.additionalContext`; the bare key is
  the SDK/Copilot shape, and the harness discards what it does not recognise. Valid JSON,
  exit 0, nothing injected, nothing logged. Every session since has run without the rule core,
  and the only symptom was behaviour that quietly did not match the rules.

  Found by comparing against `superpowers`, whose own hook carries the decisive note: Claude
  Code reads both `hookSpecificOutput` and snake_case `additional_context` *without
  deduplicating*, so a hook must emit exactly one shape. Emitting both to be portable would
  inject the core twice. This is a Claude Code plugin — `hooks.json` is already
  `${CLAUDE_PLUGIN_ROOT}`-specific — so it now emits the nested form only, in all three places:
  `session-start.py`, the jq fallback, and the last-resort literal.

  **Why the suite stayed green.** It asserted `d.get("additionalContext")` — the shape the code
  produced, not the shape the harness consumes. The test encoded the bug as the specification,
  which is the documented "don't assert against a reimplementation" trap one level up: it is not
  enough to drive the real script if you then check it against your own belief about the
  contract. `json_ok` now requires `hookEventName` *and* rejects a bare top-level
  `additionalContext` outright, so the old output fails loudly rather than passing.

  The lesson was already on the books. `post-push.sh` gets this right, and the assertion beside
  it reads: "PostToolUse output is ignored outright unless hookEventName is present, so a hook
  that emits valid JSON without it is silently dead." It was learned once for PostToolUse and
  never carried across to SessionStart.

### Changed

- **Status line: memory moved to line 1, between effort and Session.** It is a property of the
  machine, not of the session; sitting among Context and Cache Hit invited reading it as another
  per-session meter.
- **Status line: session input and output tokens now render after Context** — `in 250k · out
  12k`, from `context_window.total_input_tokens` and `total_output_tokens`. Output is the
  expensive side and the figure nothing else on the bar reported. `in` repeats the Context
  numerator by design: the pair only reads as a pair with both halves present.

  Both are asserted per line rather than by substring over the whole bar, since which line a
  widget lands on is the entirety of the change. The assertions strip the colour escapes first —
  every value is wrapped in its own, so a label and its number are never adjacent in the raw
  bytes.

---

## [1.11.3] — 2026-08-12

### Fixed

- **The update ran and said nothing.** Reported from a second machine: versions pruned, stamp
  advanced, wiring repaired — and no word to the user about any of it. The mechanism worked
  perfectly and was, from where they sat, indistinguishable from nothing happening.

  The cause is structural. The hook injects an *instruction* to report the update; whether that
  gets said is the session's decision, and it was competing with roughly 800 tokens of resident
  rules ahead of it. Two changes, one improving the odds and one removing the dependency:

  - **The update block is now injected first**, ahead of `core.md`. It is empty on every session
    but the one after an update, and on that session it is the most time-sensitive thing in the
    payload.
  - **The summary is written to `~/.claude/.my-claude-setup-last-update.md`.** Everything else
    here is an instruction, and an instruction can be ignored. The file cannot: whatever
    happened, it is on disk and readable without anyone choosing to speak.

---

## [1.11.2] — 2026-08-12

### Added

- **A way to tell "nothing to do" from "it crashed".** `selfheal.heal()` swallows every failure,
  which is correct — a repair must never break the session it was meant to improve — but from
  outside, a silent success and a silent crash are the same thing. `touch
  ~/.claude/.my-claude-setup-debug` and the next failure is appended to
  `.my-claude-setup-debug.log` instead of vanishing. Off by default, and it never changes what
  `heal()` returns.

  Worth noting where this came from: the plugin has now been bitten three times by failures that
  looked like nothing — a status line rendering from an abandoned release, a `.env` guard that
  worked on one OS and not the other, and an SVG that read as valid and rendered as an empty box.
  Silence is the failure mode this codebase produces, so it gets an escape hatch.

---

## [1.11.1] — 2026-08-12

### Removed

- **`claude-md-management` and `skill-creator` leave the tools list.** Both had been uninstalled
  on the author's machine and the roster went on advertising them, which is the same drift that
  removed `code-review` and `code-simplifier` in 1.9.0. Worth naming the reason it survived: the
  four-source invariant only covers the **companions** block. Tools are deliberately absent from
  `core.md` — nothing routes to them — so there is no second source to check them against, and no
  test can catch a stale entry there. That list is maintained by reading it.

---

## [1.11.0] — 2026-08-12

1.10.0 made the status line survive an update. This makes the *whole plugin* survive one: a user
who never runs `/setup` again still ends up on the release they are actually running.

### Changed

- **`selfheal.py` became the update path rather than a status-line patch.** On the first session
  after the installed version moves it now: diffs the outgoing release against the incoming one
  and reports what moved, grouped as resident rules, protocols, commands, hooks, status line,
  assets and docs; repairs the status-line wiring; deletes the superseded cached releases; and
  hands the session an instruction to reconcile `/setup` Part 1 — marketplaces, roster,
  `settings.json`, companion tuning — against the machine, then explain the result.

  The split is deliberate. **Python does what is deterministic**: hashing two trees, copying a
  file, deleting directories nothing points at. **The session does what needs judgement**:
  merging settings, weighing a new companion, saying what any of it means. A hook cannot reason,
  and a model should not be hashing files.

  Two limits it will not cross. It adds missing keys and **never overwrites a value the user set
  to something else** — that gets reported as a difference and left alone. And it **asks before
  installing a companion**: repairing a path this plugin wrote is the plugin's business, putting
  new software on someone's machine is theirs.

- **Superseded releases are pruned automatically.** Claude Code never removes them, and this
  machine had accumulated eleven — 1.0.0 through 1.10.0. Harmless disk now, but they were the
  mechanism behind the 1.10.0 bug: a `statusLine` pinned to an old path kept resolving into one
  of them, so the bar rendered from an abandoned release and nothing said so. The prune is
  guarded three ways — the parent must sit under the plugin cache, the name must parse as a
  version, and the installed release is never a candidate.

- **The diff runs before the prune**, because the outgoing release has to still be on disk to
  compare against. Obvious in hindsight; easy to get backwards.

---

## [1.10.0] — 2026-08-12

An update that requires the user to run a command afterwards is broken on most machines most of
the time: nobody remembers, and nothing complains. This release makes the plugin repair its own
wiring and say so.

### Added

- **`assets/statusline-launcher.mjs`** — one file, copied once to `~/.claude/statusline.mjs`,
  whose only job is to read `installed_plugins.json` and hand off to whichever release is
  installed. `settings.json` points at that stable path and never needs rewriting again. The
  indirection costs nothing measurable: 186 ms against 194 ms direct, inside the noise, because
  it is a path lookup inside the same node process rather than a second one.
- **`hooks/selfheal.py`** — runs on every session start, and does nothing at all on the ones
  where the version has not moved. When it has, it refreshes the launcher, repoints `statusLine`
  if it is still pinned to a versioned path, stamps the version, and returns a notice saying
  exactly what it changed. Scoped deliberately: it rewrites one key this plugin wrote, to a value
  this plugin owns. A status line pointing at somebody else's script is left alone, other keys
  are untouched, and every failure is swallowed — a repair that breaks the session it meant to
  improve is a net loss.

### Fixed

- **The status line silently ran a stale release.** Its path carried the plugin version, so every
  update orphaned it — and Claude Code keeps every previously installed version in the cache, so
  the old path still resolved and still ran. Nothing looked wrong. Found on the author's own
  machine mid-session: `settings.json` pointing at 1.7.0, 1.8.0 installed, **ten** versions on
  disk, and a bar that had been rendering from a release abandoned two versions earlier. A blank
  bar would have been the kinder failure.
- **Documentation that told users to re-run `/setup` after upgrading.** It was accurate advice
  for a design that should not have existed. Removed from `/setup`, and the 1.8.0 changelog entry
  now records what actually happened rather than the workaround it recommended.

---

## [1.9.0] — 2026-08-12

Everything below was found by looking at 1.8.0 again rather than by building anything new: an
independent audit, then a documentation read-through, then the first CI run this repo has ever
had. Each of the three found something the other two missed.

### Added

- **CI, and with it the end of `CI: none, confirmed`.** `.github/workflows/test.yml` runs the
  suite on **ubuntu-latest and windows-latest** on every push and pull request, plus a check that
  no `*.sh` picked up CRLF. Both platforms deliberately: this plugin exists largely because
  Windows breaks assumptions Unix tooling makes, and those breakages are invisible on ubuntu
  alone. It proved itself on the first run — see the `.env` fix below.
- **24 assertions**, 54 → 78. Four destructive patterns that were listed in the regex and tested
  nowhere; four post-push CI providers, of which only GitHub Actions had ever been exercised; six
  status-line failure paths; a `notify-send` assertion that runs on every platform, replacing a
  section that could report success having tested nothing; and the force-push regressions below.
- **A four-way roster invariant.** `setup.md`, `core.md`, `onboarding.py` and `README.md` must
  name the same companions, checked as set equality in every direction. The first version checked
  one direction only, which passes happily when a companion is *dropped* — the exact drift it
  existed to catch.

### Changed

- **The README shows the status line and what the plugin costs.** `assets/statusline.svg` is
  generated from the script's real ANSI output rather than screenshotted, so it cannot drift from
  the code the way a cropped image silently would, and a measured-cost table records the hot-path
  figures with the machine they came from stated — Windows spawn costs are several times Linux's,
  and a benchmark without its platform is a number pretending to be a fact.
- **The suite moved to `tests/suite.sh`.** `hooks/` now holds only what ships and runs. It still
  `cd`s into `hooks/`, because the hooks resolve their siblings relative to themselves and
  running from anywhere else would test a path no hook uses.

### Removed

- **`code-review` and `code-simplifier` are no longer companions**, and `commit-commands` is no
  longer installed. Claude Code ships built-in `/code-review` and `/simplify` that do the same
  jobs better, and `git-protocol` already owns commit conventions. Worse, neither could fire:
  the `code-review` plugin's single command is shadowed by the built-in of the same name, and
  `code-simplifier` ships **only an agent** — passive, invoked by nothing, while `core.md` called
  it "opt-in". Both sat in the routing table unused for over a month. A companion that cannot
  trigger is not a companion; it is a line of prose costing resident tokens to describe a tool
  nobody reaches. The roster is now six, and the suite asserts all four surfaces agree on it.
- **The reconcile step no longer removes anything.** It reports what is installed outside the
  roster, says that `claude plugin uninstall <name>` removes it, and moves on. The removing
  version needed a batched consent prompt, a reversibility promise, and a carve-out for
  hand-authored skills the promise could not cover — about forty lines defending a feature worth
  one keystroke, and the only irreversible step in a command whose premise is that running it is
  safe. Deleting the feature deleted the problem.

### Fixed

- **`guard.sh` protected `.env` on Windows and not on Linux, from an identical payload.** A
  Windows path arrives backslash-delimited, and `basename` only splits on those under MSYS — GNU
  `basename` returns `C:\repo\.env` whole, so the `.env` case never matched and the write went
  through. Separators are now normalised before matching, and the `.git` check drops its
  duplicate backslash pattern as a result. Found by the first CI run this repo has ever had:
  windows-latest 78/0, ubuntu-latest 77/1, on an assertion that had been passing locally for
  months.
- **Thirty-six mojibake sequences across all ten `security-protocol` references.** UTF-8 read as
  cp1252 and re-saved, so every em dash rendered as `â€"` and every `§` as `Â§` — in the ten
  files a session loads when it is reasoning about security. Repaired by targeted replacement
  rather than a cp1252 round trip, which would raise on any character that encoding cannot hold
  and silently rewrite bytes that were never broken.
- **The README listed install commands for two plugins that no longer exist in the roster.** That
  block was a fifth copy of the companion list and the one the suite's invariant did not cover,
  so it drifted first. It is gone; `/setup` is now the only place that says how to install them,
  and the table beside it says only what each is for.
- **Two force-push boundaries.** ERE has no `\b`, and 1.8.0 rendered it as `([[:space:]]|$)`,
  which silently un-blocked every chained form while the spaced and end-of-string forms kept
  passing — so nothing noticed. Both spellings now end on `([^a-zA-Z0-9_]|$)`, which also catches
  `--force-with-lease`: the lease protects collaborators, but the push still rewrites published
  history, and blocking only the blunt spelling would make the clearer one the way around the
  guard.
- **`post-push.sh` claimed a push landed when it could not know.** With no upstream configured
  the ahead-count is empty, and the hook went on to report "Push landed" as fact. It now says
  landing is unverified, which is the difference between a prompt and a false one.

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
  plain `git status`. The engine is now bash's own `[[ =~ ]]` and the three JSON reads collapsed
  into one `parse_all`. **655ms → 287ms**, 54 assertions still green. The greps in the
  secret-scan branch stayed: that path only runs on a commit, already pays for a `git diff`, and
  scanning a whole diff line-by-line in bash would be slower.
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

- **`assets/statusline.mjs`** — a status line in three. Line 1 is identity and spend: model,
  effort level, session cost and elapsed time. Line 2 is what the session and the machine are
  carrying: context against the model's real window, cache hit ratio, memory, and the skill
  currently in play. Line 3 is the repo: branch, and lines written this session.

  Almost every value is read straight from the payload Claude Code supplies, which knows the
  effort level and the real context-window size — deriving either from the transcript, as an
  earlier draft did, was guessing at a number the harness already had. The active skill is the
  one exception and is recovered by scanning the transcript.

  Colour is a signal, not decoration: context, cache and memory are scaled green/amber/red so
  the bar reads without parsing a number. The cache ratio floors rather than rounds — a healthy
  session sits at 99.6%, and rounding that to "100%" claims a perfect hit that did not happen.
  No dependencies and no subprocess by default; `STATUSLINE_GIT_CHANGES=1` adds a dirty-file
  count at the cost of one `git` spawn. Every failure degrades to a shorter line and exits 0.
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
  was the measured cause of the lag. As shipped in 1.8.0 the status-line path carried the plugin
  version, so an upgrade silently orphaned it; 1.10.0 replaced that with a launcher and a
  self-heal, and no longer asks anyone to re-run anything.

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
