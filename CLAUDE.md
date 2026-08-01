# my-claude-setup

> This is the plugin's *own* project file — conventions for working **on** this repo.
> It is not the config the plugin ships. That lives in `hooks/core.md` and `skills/`.

## Project

A Claude Code plugin. It injects a small always-resident rule core, loads seven protocol
references on demand, and enforces four safety hooks. Published as its own marketplace.

## Key files

- `hooks/core.md` — the resident core's text. **This is the file that replaced `CLAUDE.md`.**
  Every token here is paid on every session, so additions need to earn their place. Single
  source: `session-start.py` reads it, and `session-start.sh` re-emits it via jq when Python is
  missing. Only the last-resort branch in `session-start.sh` (no Python *and* no jq) restates
  policy, and it is deliberately reduced rather than a mirror.
- `hooks/session-start.py` — wraps `core.md` with git context and the onboarding notice.
- `hooks/session-start.sh` — dispatcher with the two fallback branches.
- `hooks/test-hooks.sh` — the hook test suite. See Verifying a change.
- `hooks/guard.sh` — all PreToolUse blocking. One script, dispatches on which field is present.
- `hooks/onboarding.py` — one-time first-run check, imported by `session-start.py`. Detects real
  state; must never nag a user who is already set up. Reads settings as **`utf-8-sig`**, because
  Windows tooling writes a BOM and plain `utf-8` would make a healthy config look absent.
- `hooks/py.sh` — interpreter resolver. Every Python entry point goes through it.
- `skills/*/SKILL.md` — the `description:` field is the router. See Gotchas.
- `.claude-plugin/` — `plugin.json` and `marketplace.json`. Bump `version` in the former on release.

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
`python`/`python3` stubbed to fail, only `py -3` real); and two consistency invariants — the
`hooks.json` matcher matches what `guard.sh` claims, and every companion in `onboarding.py` is
named in `core.md`. Slow on Windows: roughly 4s per assertion, since each spawns bash plus an
interpreter.

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

`Docs/Audit/` only. Trio promotes finished audit runs there — `codex/<date>/` is what Codex
reported, `claude/<date>/` is the adjudication: verdict per finding, the disagreements, and what
stayed open. Worth keeping because an audit's *refutations* are the part git history loses; a
commit shows what changed, not which findings were argued down and why.

Two things to know when reading one. Trio's top-level `findings` array reads `0` on a
`ceiling_reached` run even when that pass's lenses reported plenty — check
`.trio/runs/<id>/pass-N/reconcile.json`, not the summary. And a `response.json` written after the
run has ended is never ingested, so the generated `claude/` file will list everything as open;
correct it by hand before promoting.

No other `Docs/` subtree. The repo is small enough that git history is the record, and
`Docs/Plan/` is for in-flight work — nothing here stays in flight. The `project-docs` skill and
`assets/templates/` describe the convention for *consuming* projects, not for this one.
