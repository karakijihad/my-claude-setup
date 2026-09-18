# Changelog

All notable changes to this plugin. Newest release first. Releases before 1.3.0 predate this
file — see `git log --grep="bump to"`.

---

## [1.23.0] — 2026-09-16

A session has no idea how full it is. The figure exists — `context_window`, in the status-line
payload — but no hook event carries it, so `core.md`'s rule about handing off to a fresh session
was asking the model to judge a number it could not see. Sessions ran to 900k of a 1M window and
read as indifference; they were blindness. This ships the number.

### Added

- **`hooks/context-watch.sh`** — `PostToolBatch`. Injects `[context] 350k/1.0M (35%) · handoff
  budget 600k` once per 5%-of-window crossing, and a handoff directive once past budget. The
  routine line is deliberately state, not instruction: an order repeated twenty times becomes
  noise, a number does not. `PostToolBatch` rather than `PostToolUse` because the latter fires
  per tool call and runs concurrently for a parallel batch, which would race the ratchet.
  Silent on subagent payloads (`agent_id` present), silent with no state file, exit 0 everywhere.
- **The sensor in `assets/statusline.mjs`** — the status line is the only component the harness
  hands `context_window` to, so every render drops the fill into
  `~/.claude/cache/my-claude-setup/<session_id>.json`, written atomically because the reader is a
  separate process. Under `.claude/cache` rather than a temp dir: the reader is bash under Git
  Bash, where `os.tmpdir()` and `$TMPDIR` disagree. A side effect only — nothing renders
  differently, and every failure is swallowed.
- **`CLAUDE_HANDOFF_BUDGET`** — the budget, in tokens. Unset means 60% of whatever window the
  session reports, so it needs no configuration to work, and none to be right on a 200k window.

### Changed

- **`hooks/core.md`, the swarm rule** — it was the only line in the file phrased as a capability,
  "you *can* run a swarm", while every rule around it is imperative; and its test, "holding the
  files would cost more than holding the answer", had no anchor to check against. It now counts:
  four or more files means fan out, decided before the first file is opened. "Context you already
  hold" is gone — it was self-fulfilling after any inline reading, which made it the first thing
  a model reached for to justify not delegating.
- **`hooks/core.md`, the context rule** — points at the `[context]` reading rather than an
  internal estimate, and drops the compaction clause.

- **`README.md`, `skills/project-docs/SKILL.md`** — the README documented five hooks; there are
  six. And `project-docs` still told the model the status-line figure "never reaches you" and that
  "there is no threshold to wait for" — both true when written, both false as of this release.

### Audit

Trio, two passes, all five lenses plus a Claude lane each time. Pass one: fifteen findings,
fourteen confirmed, one duplicate. Pass two, on the fixed tree: ten more. The ones worth naming:

- **The sensor and the hook did not agree on where home is.** The sensor is node, spawned by the
  harness, and reads `USERPROFILE ?? HOME`; the hook is bash and read `$HOME`. On a stock Git Bash
  these name the same directory in different notations, which is why every test passed. A pinned
  `HOME`, a redirected corporate profile, or a CI image setting only one separates them — and the
  reader then looked in a directory the writer never wrote to, silently, disabling the whole
  feature. The hook now falls back to `USERPROFILE` via `cygpath`. Raised independently by two
  lenses and by neither of the two agents who wrote the code.
- **The prune swept the whole cache directory on every render** — an O(files) sweep in the one path
  this change was required not to slow, and the file's own header says cost here is visible
  terminal lag. Now sampled at roughly one render in fifty.
- **The hook paid an interpreter spawn before it could decide to stay quiet.** It fires on every
  tool batch and almost always exits silently at the ratchet; `lib-parse.sh` documents those spawns
  at 90-200ms on Windows. `session_id` and `agent_id` now come from a bash regex, with the
  interpreter kept as the fallback it should always have been.
- **Declined:** the ratchet degrades toward noise rather than silence if its `-O` ownership test
  misreports on Git Bash. `budget.sh` has carried the identical guard and the identical degradation
  since it shipped; fixing one and not the other would be worse than the fault. It is a known edge,
  not a regression, and belongs to whichever release fixes both.

Pass two found that the fix for the first pass was half a fix:

- **The cheap payload read trusted a guess.** Reading `session_id` with a regex is free, but a
  regex takes the first match and a `PostToolBatch` payload carries the whole `tool_calls` array —
  so a tool whose *structured* input has a `session_id` key of its own wins. Pass one's answer was
  to re-read properly when the guessed id had no state file. Pass two pointed out the hole in that:
  a nested id naming a *different session still inside the prune window* does have one, and its
  fill was then reported as this session's. The count decides now, not the match — exactly one
  `"session_id"` key and zero `"agent_id"` keys means the match is unambiguous, anything else goes
  to the interpreter. Still no process in the common case, and the guess is provably safe rather
  than hopefully safe. Fixing it also deleted the two retry paths pass two's simplifier lane had
  flagged as fragile.
- **`??` is not `||`.** `USERPROFILE ?? HOME` falls through only on null or undefined, so a shell
  or CI image exporting `USERPROFILE=""` selected the empty value and every path resolved against
  the process cwd. The same line was in `statusline-launcher.mjs`, where it blanks the entire
  status line rather than just the sensor — a pre-existing bug this audit found by accident.
- **A mode on `mkdirSync` does nothing to a directory that already exists.** The `0700` only ever
  applied to a cache directory this release created; one left from before kept whatever the umask
  gave it. It is chmodded explicitly now.
- **The end-to-end fixture was not end-to-end.** The HOME/USERPROFILE test wrote the cache file
  with `printf` and never invoked the sensor, so it pinned the read side of a two-process contract
  and called it both.
- **`at` is gone.** Pass one answered "nothing reads this field" by documenting it. Pass two raised
  it again and was right to: a comment explains a field, it does not justify one. `mtime` already
  says when the file was written.

### Known

- `lib-parse.sh` gains a CR on every newline inside a multi-line field on Windows: this `jq`
  opens piped stdout in text mode. Verified harmless today — `guard.sh`'s patterns are
  substring-based and still block a token on a second line, and `subagent-verify.sh` still
  refuses an unverified `done` — and both are now pinned by tests. It becomes a live bug the day
  a pattern is end-anchored. `context-watch.sh` strips CR on every branch rather than reuse that
  scheme.

## [1.22.0] — 2026-09-13

The Agent tool can set a subagent's model but not its effort — effort comes only from an
agent's definition. So a swarm or a consult ran at whatever the harness gave a
`general-purpose` agent, which is undocumented. The plugin now ships the definitions.

### Added

- **`agents/worker.md`** — the default for delegated work (code on a file set, research,
  tests), `effort: high`. Restates the brief-and-report contract `agent-protocol` sets.
- **`agents/advisor.md`** — advice-only, read-only, `effort: high`. "Consult fable" dispatches
  it with `model: fable`; a model passed on the call overrides the definition, so one card
  serves any model. When Codex is named too, `trio:trio-consult` runs alongside, each blind to
  the other.
- `core.md` and `agent-protocol` route delegated work to `worker` and consults to `advisor`
  instead of `general-purpose`.

---

## [1.21.0] — 2026-09-13

A full read-through by parallel agents found guard bypasses, a subagent gate that turned
itself off on common formatting, and stale docs. It also found that the orchestration model —
run a swarm, keep your own context low, hand off when a fresh session would do better — was
spread across skills instead of stated where every session reads it.

### Added

- **Model tiers, shipped blank.** `/setup` asks for an orchestrator, subagent and advisor model
  and writes only what the user names (`model`, `env.CLAUDE_CODE_SUBAGENT_MODEL`,
  `env.MY_CLAUDE_SETUP_ADVISOR_MODEL`). `session-start.py` names whichever are set in one
  line; values must look like a model alias, so a config key can't carry instructions.
- **`core.md` states the orchestration model**: you can run a swarm and choose it by file
  sets; context is the orchestrator's budget; hand off when a fresh session serves the
  objective better. Consult (advice before a choice) and audit (review of finished work) are
  named as different jobs.

### Fixed

- **`guard.sh` bypasses**: the PowerShell tool skipped the guard and `post-push.sh` entirely
  (both matchers now name it, and `Remove-Item -Recurse -Force` on a root is blocked); split flags
  (`rm -r -f`), quoted targets and a root's children (`C:\*`, `~/*`) for `rm` and `Remove-Item`
  alike, and its `rm`/`ri`/`del`/`rd` aliases), `git clean -d -f`, `--no-verify` behind any
  `git -c key=value`, a quoted `-c "commit.gpgsign=false"`, and case-varied
  protected files (`.ENV`, `Package-Lock.json`, `.GIT/`) all got through. The same `-c` gap
  skipped the staged-secret scan for any commit written that way.
- **`subagent-verify.sh`** only recognised `**Label:**`; `**Label**:` or plain `Label:` switched
  the gate off. Now any of those count, while unbolded `PASS: 10` lines in pasted output stay
  output.
- **`selfheal.py`** said nothing when `settings.json` failed to parse and the status-line check
  was skipped.
- **Docs templates** described the old single `HANDOFF.md` and sent audit results to
  `Doclog/` and `Sessions/`; a security reference pointed at a "session note"; mojibake arrows.
- **Resuming a handoff** now says to continue from its `Next:`, not only to report status.

### Changed

- **Onboarding no longer flags an unset subagent model** — blank is the default now.
- **`session-start.py`** drops the toplevel lookup left over from the deleted handoff pickup.

## [1.20.0] — 2026-09-11

The handoff shipped with a pickup mechanism: a SessionStart hook that worked out whether a
session had been compacted, resumed or cleared, found the handoff, decided whether to trust
it, and loaded it. All of that existed to answer one question automatically — *which handoff,
and can I trust it* — and the operator pasting a path answers it for free.

So it is gone, and the feature is what it should have been: **the session judges its own
context, writes the handoff, gives the operator the path, and says to start a new session.**

### Removed

- **`resumption_notice`, `_age` and `_repo_root` from `session-start.py`**, the payload-source
  parsing in `main()`, and the whole handoff branch of `session-start.sh`'s jq fallback. That
  file is 150 lines where it was ~330. Gone with them: the tracked-vs-local provenance check
  and the case-insensitivity bypass it turned out to have, the symlink guard, the 4000-byte
  cap, the truncation marker, the age arithmetic, and a second copy of all of it in bash.
- **The `/clear` question.** It asked whether to resume from a handoff it had found. Nothing
  looks for one now, so there is nothing to ask about.

### Changed

- **Handoffs live at `Docs/Handoff/<YYYY-MM-DD>/<slug>.md`**, not one overwritten file. One
  file was wrong the moment two sessions worked on two features: the second overwrote the
  first and that work was simply lost. Dated folders and a slug per piece of work cannot
  collide, and the ambiguity that shape would have caused — which of three is mine? — costs
  nothing now that a person names the path instead of a hook guessing it.
- **`budget.sh` keys the handoff on its folder, not a filename**, since the file is named for
  the work it describes.

## [1.19.0] — 2026-09-11

The four findings 1.18.0 shipped with open, and a CI check that turned out never to have
worked on one of its two platforms.

### Fixed

- **The line-ending check never looked for a carriage return on ubuntu.** It shelled out per
  file with `find -exec sh -c`, and `sh` is dash there, which has no `$'...'` ANSI-C quoting —
  so `$'\r'` reached grep as the literal pattern `$\r`, a dollar followed by an r. It passed
  for as long as no `*.sh` contained `$r`, then failed the day one did: `[ -n "$ran" ]`, added
  to `lib-parse.sh` in 1.18.0. Windows was green throughout because Git Bash's `sh` *is* bash.
  A check that cannot fail for the right reason is worse than none, because it is trusted —
  and this one is half the reason the Windows leg exists. It now counts CR bytes with `tr`,
  with no nested shell and no carriage return passed as an argument; `grep -rlU $'\r'` fixes
  the quoting and is wrong a second way, since under MSYS a lone CR argument does not survive
  into grep and every file matches.

### Changed

- **`post-push.sh` reads its payload with `parse_all`, and `parse_field` is gone.** It was the
  last caller of a helper that duplicated `parse_all`'s jq-then-Python fallback in full, and it
  fires on *every* Bash call — paying a spawn per field, which is the exact cost `parse_all`
  was written to collapse when `guard.sh` stopped doing it. Removing it also orphaned
  `_have_jq`, so two implementations became one.
- **Session start resolves git once and caches it.** A single
  `rev-parse --show-toplevel --abbrev-ref HEAD` answers both questions anything here asks of
  git, against a repo whose own `lib-parse.sh` header measures process spawns at 90–200ms on
  Windows and rewrote a parser to avoid three of them.
- **The handoff's age comes from a `Written:` date in the file, not the filesystem.** mtime is
  a property of the file rather than of the handoff: a restore, a copy, or any tool that
  rewrites it resets the clock, so a fortnight-old handoff claimed to be minutes old at exactly
  the moment the operator is judging whether it is still live. mtime remains the fallback and the
  answer now says which it used — an age you cannot source is one more thing to distrust.
- **The handoff budget is 45 lines, not 30.** The template alone was 29, so a correctly filled
  handoff — three things done, two remaining, three artifacts — crossed the budget while being
  exactly the document the template describes. A budget that fires on correct use is one the
  session learns to dismiss, which is the failure the ratchet was designed to avoid.

## [1.18.0] — 2026-09-11

Two pruning passes and three consults. Fable 5.1 measured what the plugin charges before a
session does anything — `core.md` plus eight skill `description:` fields plus the reviewer
notice, ~1,570 tokens paid every session, forever — and found roughly a third of it was
rationale, duplication, or a rule the harness now contradicts. GPT-6-Astra took a second pass
at the remainder and corrected two of the first pass's reasons along the way. Codex audited
the result through four lenses: seven findings fixed, two argued down.

**~1,570 → ~1,035 resident tokens**, with the fan-out rule *and* the handoff added on top of
the cut.

### Added

- **`subagent-verify.sh`** — SubagentStop. `agent-protocol` has always required a sub-agent's
  report to carry pasted verify output, and prose could not make it so: the orchestrator reads
  a confident `done` and integrates work nothing ran. Now an agent that claims `done` with
  changed files and no verify output is blocked, and the reason is fed back so it can produce
  one. Read-only agents, honest `partial` reports, and messages with no report block at all
  pass untouched, and `stop_hook_active` ends it after one nudge.
- **The fan-out rule, in the resident core** — *by file sets, not task count*. A read goes to
  parallel agents when holding the files would cost more than holding the answer; writes fan
  out only into disjoint file sets, each with its own verify command. A shared file, an
  unfixed interface, layers of one feature, or context already in hand means do it in-line.
  The old trigger ("2+ independent tasks") fired on layered features, where the parallelism is
  fictional, and missed the read case, which is the one that actually pays.
- **`parse_stop` in `lib-parse.sh`** — `parse_field` returns `""` for a JSON boolean on its
  Python branch and `"true"` on its jq branch, so the loop guard would have read as absent on
  exactly the machines this plugin exists for.
- **The handoff — `Docs/Handoff/<date>/<slug>.md`.** A session that runs out of room
  mid-work loses the detail behind it and leaves the next one inferring. It now writes
  down where the work stood — objective, what is done with the evidence that proves it,
  what remains, what is blocked, which review rung it reached — and hands the operator
  that path to open a fresh session with. Labelled lines and bullets, no headings;
  `budget.sh` holds it to 45 lines with the remedy *a handoff is a position, not a
  narrative*.

### Removed

- **`notify.sh` and its `Notification` hook.** A desktop toast steers no behaviour, and the
  sanitizer it needed to interpolate a message into `osascript` and PowerShell safely cost
  three audit findings to get right. Maintenance with nothing on the other side.
- **`dependency-auditor`.** Its command tables were worth keeping and are now in
  `security-protocol/references/06-Dependencies.md`, where they cost nothing until read. As a
  skill it paid ~65 resident tokens per session for a description that was a keyword list —
  the vocabulary routing this repo's own conventions forbid.
- **`feedback-protocol`.** 110 lines describing what auto-memory now does mechanically. The
  one part memory does not cover is a destination, and that is one line in `project-docs`:
  once is a one-off and belongs in memory, twice is a rule and belongs in `CLAUDE.md`.
- **The protocol list in `core.md`.** Skill descriptions are the router and are already
  resident; the list was a second, hand-maintained copy of them — the drift this repo's own
  Gotchas warn about, sitting in the most expensive file it owns.
- **The `Read`-over-`cat` paragraph.** It contradicted the harness: auto mode instructs the
  opposite, so the two fought on every read. The one idea worth keeping — narrow large output
  at the source — survives in the shell-gating line.

### Changed

- **`core.md` carries the same rules in fewer words.** Rationale moved out (this file is where
  it belongs); duplicated companion assignments merged into the ladder. Net effect after
  *adding* the fan-out paragraph: **750 words → 637**. Four rules were caught going out with
  the rationale and put back in self-review — "say nothing if there is nothing new", "don't
  improve adjacent code", narrowing large output at the source, and which superpowers skills
  are in scope.
- **`agent-protocol` is two artefacts instead of seven sections** — the six-field brief you
  send, and the four-field report you demand back. The orchestration prose, the delegation
  table (a stale hand-copy of the agent list the harness injects anyway), the context-budget
  advice and the closing checklist are gone; the rule they circled lives in the core, and the
  report is now enforced by a hook.
- **Skill descriptions are triggers only — 380 words → 139.** Per this repo's own routing
  rule: framework names out of `testing-protocol`, "any other git interaction" out of
  `git-protocol` (it fired on `git status`), the coverage-list-then-trigger-list duplication
  out of `security-protocol`, and plan files out of `project-docs`, where two skills were
  claiming one trigger — the collision the router exists to prevent. Then a second pass: six
  of them still opened by summarising their own contents before saying when to fire, and a
  contents summary does not route.
- **A second pruning pass, after a consult with GPT-6-Astra.** It corrected two of the four
  reasons behind the first pass — the reviewer notice is redundant because `core.md` already
  *orders* the reviewer, not because the harness lists the agent (availability is not
  dispatch); and prompt-shape routing is wrong because prompt shape is a poor classifier, not
  because 1.4.0 settled it. It also found the largest remaining duplication, which was a day
  old: the fan-out paragraph carried brief fields and report-checking that `agent-protocol`
  already owned. The resident core keeps the *decision*; the mechanics went to the skill.
- **`core.md` defers to `planning-protocol` before the offer, not after accepting one.** It
  had duplicated the tripwire, the offer wording and the declined-plan behaviour that
  `planning-protocol` §1–2 already own — and deferring only on acceptance meant the skill
  arrived after its own decision point.
- **The Tier-2 reviewer notice speaks only when the reviewer is missing.** The installed
  branch restated a resident instruction at resident cost, every session, forever. The absent
  branch is hedged now: it reads *settings*, not the live agent list, so an unparsable
  settings file looked exactly like a plugin that was not enabled.
- **`post-push.sh` matches with `[[ =~ ]]` instead of `echo | grep`**, which forked twice on
  every Bash call in the session — the exact cost its "cheapest rejections first" ordering
  exists to avoid. It now also names `/loop` for the one case that is genuinely a poll: CI
  still running after the work is done.

### Fixed

- **`post-push.sh` announced a landed push for `git --no-pager log --grep push`.** Present since
  the matcher was written, and found by the Tier-2 review of this release. A generic "option,
  then optionally one non-option word" rule cannot tell `-C /r` from `--no-pager log`, and a
  regex engine needs only one valid decomposition to report a match — so `log` was parsed as
  `--no-pager`'s argument and the trailing `push` satisfied the pattern. The seven git options
  that take their value as the next word are now named; every other flag stands alone or
  carries its value with `=`. The old negative case had no leading flag, so nothing caught it.
- **`subagent-verify.sh`'s parser could be padded past its own evidence threshold.** An
  unrecognised bolded label fell through to the accumulator, so `- **Note:** could not run the
  tests here` written under an empty `Verify output:` counted as the output — the excuse
  satisfying the check it was excusing. Any line-initial label now closes the open section.

## [1.17.0] — 2026-08-21

Measured on a real project using this plugin: a plan index at 1,039 lines, 745 of them a
prose chronicle of work git already records. Its phase table was 90 lines and was doing the
whole job. None of it broke a rule, because no rule covered plan documents at all.

### Added

- **`budget.sh`** — PostToolUse on `Write|Edit`. Warns when a plan index, phase file, backlog
  or code map outgrows its budget; never blocks. Ratcheted: it speaks on the first crossing
  and again only when an edit makes the overage worse, so the edits that fix a file never nag.
- **Templates carrying those budgets in their headers** — `plan-index.md`, `plan-phase.md`,
  `backlog.md`, `codemap.md`. A suite assertion pins them to the numbers the hook enforces.
- **`Docs/Plan/BACKLOG.md` and `Docs/CODEMAP.md`** as permitted files in `project-docs`.

### Changed

- **The plan folder is back**, one release after 1.16.0 removed it. `INDEX.md` and
  `phase-N-<slug>.md` are normative names now, because the hook keys its table on them.
- **`planning-protocol` §3 overrides `superpowers:writing-plans` on document shape.** Its
  scope check, right-sizing and no-placeholders rule still apply; "assume the engineer has
  zero context" and the inline code per step do not.
- **Superseded scope is deleted**, with one line surviving in the index's locked decisions.
- **A completed plan is deleted, never archived.** `Plan/README.md` had said otherwise.
- **A maintained code map is permitted** rather than forbidden, on two conditions: roles not
  histories, and a named regeneration trigger. People who need one keep it anyway, and an
  unsanctioned map is an unbudgeted one.
- **`guard.sh`, `post-push.sh` and `budget.sh` read stdin with a builtin** instead of
  spawning `cat` on every call.

### Removed

- **`skill-security-auditor`** — 1,577 lines: a 1,139-line Python scanner, a 271-line threat
  model, a 167-line skill. A standalone static-analysis product living inside a rules plugin.
  `security-protocol` §07 now says what to look for when reading an untrusted skill, which is
  what the scanner was a proxy for.

### Simplified

This release was reviewed for overbuild after the owner pointed out that a request for a hard
rule had produced a hook, four templates and 294 lines of tests. **5,713 shipped lines → 4,002,
with all 112 assertions still passing.**

- `planning-protocol` and `project-docs` stated the same document structure, budgets and
  git-is-history argument twice — 324 lines → 238, split by the question each answers:
  planning-protocol owns *when and how to execute*, project-docs owns *where and how big*.
- `budget.sh` 230 → 130, and its test block 218 → 160, with no assertion dropped.
- The four new templates 152 → 124.
- `setup.md`'s allowlist essay compressed; every action it performs is unchanged.

## [1.16.0] — 2026-08-16

### Changed

- **The planning trigger is now a count.** It was "ordered phases that won't fit one context" —
  two conditions, one of them a prediction about my own context that errs in one direction only.
  "This will fit" is the normal way a plan doesn't get written, and the cost arrives later, on
  the session resuming from a summary. Four ordered phases now flips the default: offer unless
  you can name why it all fits one window. Under four, both conditions still apply. Counting
  phases is checkable; predicting context is not. In `core.md` and `planning-protocol` §1.

### Removed

- **The ~6-phase split to a `Docs/Plan/<topic>/` directory with an `INDEX.md`.** Two numbers in
  one protocol read as one limit, and the second one was never worth the confusion: a plan long
  enough to need an index to navigate is a plan carrying too many phases, and the fix is cutting
  scope or closing phases, not adding a second file layer to walk. One plan is one file now,
  whatever the phase count. Four — the §1 tripwire — is the protocol's only number.

## [1.15.0] — 2026-08-16

A plan file exists because the work won't fit one context — which means every phase after the
first is started by a session that wasn't there when the plan was written, against a codebase
that kept moving in between. The protocol verified the plan's own *claims* on resume and
nothing else, so a phase could confidently edit a path that had since been renamed.

### Added

- **A scout pass before each phase**, in `planning-protocol` §4. An `Explore` agent re-checks
  the phase against current code on a four-question brief: do the named paths and symbols still
  exist, do the assumptions still hold, has any of it already landed, and — the one the first
  three miss — has adjacent work appeared that the phase must now account for. The brief is
  closed deliberately: a scout that also reviews or proposes is a phase being redesigned by an
  agent that cannot see the plan. Findings are reconciled into the phase text *before* the first
  edit, and drift that moves scope-out or ordering is reported to the user rather than absorbed,
  because it changes the plan they agreed to.

- **`Scouted: <date> @ <sha>` in the resumption header**, which doubles as the skip condition.
  Closing one phase and opening the next in the same session, against a tree only you have
  touched, dispatches nothing — `HEAD` still matches the stamp, so nothing has moved. The cost
  lands where the risk is: resuming days later. `Explore` rather than a main-context grep for the
  same reason the plan file exists at all — a sweep run in the main context spends on file dumps
  the budget the phase needs — with an exception for a phase naming two or three concrete files,
  where the agent round-trip costs more than the answer.

- **A pointer line carried in the plan file itself**, under the header, and in the `INDEX.md` of a
  split plan. A resuming session reads the plan, not necessarily this skill, so a rule that lives
  only in the skill may never be read. It stays a pointer and never a copy of §4 — a plan written
  months ago would otherwise carry a stale mechanism and be believed. The shipped
  `Docs-skeleton/Plan/README.md` states the same line.

## [1.14.0] — 2026-08-14

Prompted by Claude Code 2.1.229 → 2.1.232, which tightened the static analysis deciding whether a
Bash call needs a confirmation prompt. Audited by Trio over three passes, which reversed this
release's own first reasoning twice — see below. The adjudication is not linked here: `Docs/` is
gitignored in this repo, so it exists only in a working copy.

### Added

- **A command-shape rule in the resident core**, deliberately version-independent. Claude Code
  updates itself and this analysis changes release to release, so a rule enumerating one version's
  rejections would be stale config that reads like fact. It states the durable half instead —
  literal absolute paths, `Write` over a `cat` heredoc, reshape a command that prompts rather than
  clicking through — and says what does *not* need avoiding: `&&` chains and shell variables both
  pass. A compound call is evaluated per subcommand. A prompt-fatigue fix, not a security one.

- **`Bash(node:*)` in the allowlist `/setup` merges**, and an honest account of what that list
  already permitted. `npm exec <pkg>` and `pnpm dlx <pkg>` fetch a package from the registry and run
  it with **no confirmation prompt** under the shipped `defaultMode: "auto"` — driven and confirmed,
  not inferred. The pre-existing `Bash(npm:*)`/`Bash(pnpm:*)` entries have always granted this; the
  caveat now says so, names dropping those two as the edit that closes it — with its cost stated —
  and stops implying `guard.sh` covers it. `Bash(npx:*)` is absent, and the caveat is precise about
  what that buys: permission rules match command *text*, so `Bash(npm:*)` matches `npm exec <pkg>`
  but not `npx <pkg>`. A literal `npx` call does prompt; the capability is still reachable without
  one. Worth doing, not a safety measure.

- **Three assertions on that allowlist**, replacing two weaker ones. The union is asserted as an
  **exact** reviewed set rather than filtered through a denylist of bad names, because a denylist
  only catches the wrapper someone thought of. Exact equality means a future change to shipped
  permissions fails the suite until a human edits the test too. All three parse every rule in the
  row — not only `Bash(...)` — bind to the unique section-1.4 row, and fail rather than pass when
  they cannot read it whole.

---

## [1.13.0] — 2026-08-14

### Added

- **A context-economy rule in the resident core.** Reading a file through `cat`, `head`, `tail`
  or a shell pipe into `grep` puts the whole output in context, unindexed and unre-readable, so
  a Bash file dump costs what an outline would have. The dedicated tools return line-anchored
  excerpts instead. The harness already warns about this after the tokens are spent; the core now
  says it before. One line, because the rule is cheap to state and the failure is expensive.

  `CLAUDE.md` told contributors to prefer the dedicated tools, but that file governs work *on*
  this repo — it was never in the config the plugin ships.

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

- **`assets/statusline.svg` regenerated**, so the README's picture shows the layout above rather
  than the one it replaced. Produced by running the script, as before. One colour moved with it:
  the time hue is 256-index 109, which is `#87afaf` — the previous file had `#87afd7`, index 110.

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
