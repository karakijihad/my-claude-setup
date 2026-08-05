# my-claude-setup

> This is the plugin's *own* project file — conventions for working **on** this repo.
> It is not the config the plugin ships. That lives in `hooks/core.md` and `skills/`.

## Project

A Claude Code plugin. It injects a small always-resident rule core, loads seven protocol
references on demand, and enforces three safety hooks. Published as its own marketplace.

## Key files

- `hooks/core.md` — the resident core's text. **This is the file that replaced `CLAUDE.md`.**
  Every token here is paid on every session, so additions need to earn their place. Single
  source: `session-start.py` reads it, and `session-start.sh` re-emits it via jq when Python is
  missing. Only the last-resort branch in `session-start.sh` (no Python *and* no jq) restates
  policy, and it is deliberately reduced rather than a mirror.
- `hooks/session-start.py` — wraps `core.md` with git context, the Tier-2 reviewer notice, and
  the onboarding notice. The reviewer notice exists because `feature-dev` ships *agents*, and an
  agent is passive — trio and superpowers both announce themselves from their own SessionStart
  injection, so Tier 2 was the only rung of the ladder that could fail silently. It is
  conditional on `enabledPlugins`: when feature-dev is absent it says so rather than staying
  quiet, since a review that never happened must not read like one that did.
- `hooks/session-start.sh` — dispatcher with the two fallback branches.
- `hooks/test-hooks.sh` — the hook test suite. See Verifying a change.
- `hooks/guard.sh` — all PreToolUse blocking. One script, dispatches on which field is present.
- `hooks/onboarding.py` — one-time first-run check, imported by `session-start.py`. Detects real
  state; must never nag a user who is already set up. Reads settings as **`utf-8-sig`**, because
  Windows tooling writes a BOM and plain `utf-8` would make a healthy config look absent.
- `hooks/py.sh` — interpreter resolver. Every Python entry point goes through it.
- `skills/*/SKILL.md` — the `description:` field is the router. See Gotchas. Descriptions are
  resident in the system prompt for **every** session, so they are budgeted like `core.md`: name
  the trigger situations, not the topic vocabulary, and keep each near 30–70 tokens.
- `commands/` — `setup`, `bootstrap-project` (blank slate), `repo-fix` (existing repo, surveys
  before it writes).
- `.claude-plugin/` — `plugin.json` and `marketplace.json`. Bump `version` in the former on
  release, and add the section to `CHANGELOG.md` in the same commit.

## Gotchas

- **Never invoke `python3` directly**, in a hook, a skill, or a script. On Windows that name is
  usually a 0-byte Microsoft Store alias stub that exits 9009, and installing Python does not
  displace it. Route through `hooks/py.sh`, which executes candidates instead of trusting names.
- **Hooks must fail open.** A hook that errors should exit 0, never 2. Exit 2 blocks the tool
  call — reserve it for a deliberate, explained block. The one exception is a genuine safety
  refusal in `guard.sh`.
- **A skill's `description:` is the routing mechanism.** There is no keyword table any more; the
  old regex router was deleted precisely because descriptions do it better. If a protocol stops
  firing when it should, fix the description — do not add a hook.
- **`*.sh` must stay LF.** `.gitattributes` pins this. With `core.autocrlf=true` on Windows,
  `text=auto` checks scripts out as CRLF and bash dies with `bad interpreter`.
- **`hooks.json` paths are `${CLAUDE_PLUGIN_ROOT}`-relative.** Never `~/.claude/`. Commands
  already run under `"shell": "bash"`, so don't prefix `bash` — it spawns a nested shell.
- **Don't ship personal config.** No absolute paths, no `enabledPlugins`, no model choice. The
  `/setup` command merges preferences into the user's `settings.json` with a diff and a prompt;
  a plugin cannot set those keys itself.

## Verifying a change

```bash
bash hooks/test-hooks.sh   # exit 0 means every assertion passed
```

Covers both hook outputs as JSON; every guard block and allow, including backslash paths and
`notebook_path`; the commit secret scan against a real staged diff; the notify sanitizer, driven
through a stub backend on `PATH`; both fallback branches; the Windows interpreter layout (jq and
`python`/`python3` stubbed to fail, only `py -3` real); and four consistency invariants — the
`hooks.json` matcher matches what `guard.sh` claims, every companion in `onboarding.py` is
named in `core.md`, this repo's `.gitignore` carries the anchored `/Docs/` the convention ships,
and every surface stating the Docs rule also names its `Docs policy` opt-out. Slow on Windows:
roughly 4s per assertion, since each spawns bash plus an interpreter. The last two are prose
invariants — they exist because that rule is stated in six files and drift there is silent.

Add a case for anything you change. Traps worth knowing before you write one:

- **Never put a literal destructive string in a test file.** `guard.sh` inspects the text of the
  command that invokes it, so a literal `rm -rf /` blocks the test run itself. Assemble such
  fixtures at runtime — this is exactly how the previous version of this section broke.
- **Redirect stdin from `/dev/null`.** `session-start.py` drains stdin, so a test that runs it
  without an EOF hangs rather than failing.
- **Never write a literal value-shaped secret either.** `guard.sh` scans the staged diff on
  commit, so a real-looking `key = "..."` in a fixture blocks the commit that adds it. Build
  those at runtime too.
- **Don't assert against a reimplementation of the thing you're testing.** An assertion that
  recomputes `notify.sh`'s sanitizer stays green after the sanitizer is deleted. Drive the
  script and inspect what it actually produced.
- **Guard `mktemp`.** `TMP=$(mktemp -d) && cp ...` does not stop the script; a later
  `> "$TMP/x"` with an empty `TMP` writes to `/x`.

## Docs

**The whole `Docs/` tree is gitignored — `/Docs/`, root-anchored, subfolders included.** Nothing
under it is committed, and that holds for folders nobody has created yet: the rule names the
directory precisely so a subfolder invented later is covered without anyone remembering a
`.gitignore` edit. The tree is working evidence, and some of it is private. Committing it is a
legitimate choice for a project, but it must be written into *that* project's `CLAUDE.md` under
a `Docs policy` heading, or the next session re-adds the line. This is the shipped default, not
just this repo's habit: `project-docs` owns the rule, `/bootstrap-project` writes it, `/repo-fix`
offers it as a choice, and both templates repeat it.

Two traps that cost real time, both verified with `git check-ignore -v`. The anchor matters:
bare `Docs/` also swallows a nested `packages/*/Docs/`. And `core.ignorecase=true` is the
default on Windows and macOS, so `/Docs/` matches a lowercase `docs/` as well — anchoring does
**not** save you — which silently ignores a published mkdocs/Docusaurus site. That is also why
`assets/templates/Docs-skeleton/` carries that name: call it `Docs/` and the plugin stops
shipping its own templates.

This repo's tree is `Docs/Audit/`. Trio promotes finished audit runs there — `codex/<date>/` is
what Codex reported, `claude/<date>/` is the adjudication: verdict per finding, the
disagreements, and what stayed open. Worth keeping on disk because an audit's *refutations* are
the part git history loses; a commit shows what changed, not which findings were argued down
and why.

Two quirks when reading one. Trio's top-level `findings` array reads `0` on a
`ceiling_reached` run even when that pass's lenses reported plenty — check
`.trio/runs/<id>/pass-N/reconcile.json`, not the summary. And a `response.json` written after the
run has ended is never ingested, so the generated `claude/` file will list everything as open;
correct it by hand before promoting.

No other `Docs/` subtree — and as of 1.5.0 that is the shipped convention rather than an
exemption from it. `project-docs` went from seven trees to three (`Decisions/`, `Audit/`,
`Plan/`) because this repo had already voted with its feet: the folders it never bothered to
create were exactly the ones git already covered. If the maintainer won't run his own
convention, it was the convention that was wrong.

`CHANGELOG.md` is the exception that proves it — a changelog is read by people who don't have
your working copy, so it lives at the **repo root** and is committed, never under the gitignored
`Docs/`. Add its section in the same commit as the `plugin.json` version bump.
