# my-claude-setup

> This is the plugin's *own* project file — conventions for working **on** this repo.
> It is not the config the plugin ships. That lives in `hooks/core.md` and `skills/`.
>
> Rules and traps only. The history behind any of them is in `CHANGELOG.md`.

## Project

A Claude Code plugin. It injects a small always-resident rule core, loads seven protocol
references on demand, and enforces three safety hooks. Published as its own marketplace.

## Key files

- `hooks/core.md` — the resident core's text, and the single source for it. Every token is paid
  on every session, so additions must earn their place. `session-start.py` reads it;
  `session-start.sh` re-emits it via jq when Python is missing. Only the last-resort branch
  (no Python *and* no jq) restates policy, deliberately reduced rather than mirrored.
- `hooks/session-start.py` — wraps `core.md` with git context, the Tier-2 reviewer notice, and
  the onboarding notice. The reviewer notice is conditional on `enabledPlugins`: when
  feature-dev is absent it says so, because a review that never happened must not read like one
  that did.
- `hooks/session-start.sh` — dispatcher with the two fallback branches.
- `hooks/guard.sh` — all PreToolUse blocking. One script, dispatches on which field is present.
- `hooks/post-push.sh` — the only PostToolUse hook, and the whole of the CI feature. Fires on
  every Bash call, so its rejections are ordered cheapest-first. Prints nothing unless a push
  landed *and* the repo has CI config; with no upstream configured it speaks but says landing is
  unverified. Exit 0 on every path — PostToolUse cannot block the call it follows.
- `hooks/onboarding.py` — one-time first-run check, imported by `session-start.py`. Must never
  nag a user who is already set up. Reads settings as **`utf-8-sig`**: Windows tooling writes a
  BOM, and plain `utf-8` makes a healthy config look absent.
- `hooks/selfheal.py` — the update path, imported by `session-start.py`. Silent except on the
  first session after the installed version moves. The split is the design: **Python does what
  is deterministic** (diff outgoing against incoming, repair status-line wiring, prune superseded
  releases); **the session does what needs judgement**, via an instruction to reconcile `/setup`
  Part 1 against the machine. It adds missing keys and never overwrites a user's value;
  installing a companion is always asked about. **The diff runs before the prune** — the outgoing
  release must still exist to compare against.
- `hooks/py.sh` — interpreter resolver. Every Python entry point goes through it.
- `assets/statusline-launcher.mjs` — the stable path `settings.json` points at, because the
  plugin's own directory is version-pinned and pointing there directly fails *quietly*: old
  versions stay cached, so the stale path keeps resolving and the bar renders from a dead release.
- `skills/*/SKILL.md` — the `description:` field is the router (see Gotchas). Descriptions are
  resident in the system prompt for **every** session, so budget them like `core.md`: name the
  trigger situations, not the topic vocabulary, ~30–70 tokens each.
- `commands/` — `setup`, and it is the only one. Part 1 sets up a machine; Part 2 sets up a
  project, scaffolding a blank slate or surveying an existing repo before it writes.
- `tests/suite.sh` — the whole test suite. Lives outside `hooks/` because `hooks/` is what ships;
  it still `cd`s there, since hooks resolve their siblings relative to themselves.
- `.claude-plugin/` — `plugin.json` and `marketplace.json`. Bump `version` on release, and add
  the `CHANGELOG.md` section in the same commit.

## Gotchas

- **Never invoke `python3` directly**, in a hook, a skill, or a script. On Windows that name is
  usually a 0-byte Microsoft Store alias stub that exits 9009, and installing Python does not
  displace it. Route through `hooks/py.sh`, which executes candidates instead of trusting names.
- **Hooks must fail open.** A hook that errors should exit 0, never 2. Exit 2 blocks the tool
  call — reserve it for a deliberate, explained block. The one exception is a genuine safety
  refusal in `guard.sh`.
- **Match the harness's JSON contract exactly.** SessionStart and PostToolUse output is read from
  `hookSpecificOutput.additionalContext` **with `hookEventName` set**. Anything else — including
  a bare top-level `additionalContext`, which is the SDK/Copilot shape — is discarded silently:
  valid JSON, exit 0, nothing injected, nothing logged. Emit exactly one shape; Claude Code reads
  `hookSpecificOutput` *and* snake_case `additional_context` without deduplicating, so hedging
  double-injects.
- **A skill's `description:` is the routing mechanism.** There is no keyword table; the old regex
  router was deleted because descriptions do it better. If a protocol stops firing when it
  should, fix the description — do not add a hook.
- **`*.sh` must stay LF.** `.gitattributes` pins this. With `core.autocrlf=true` on Windows,
  `text=auto` checks scripts out as CRLF and bash dies with `bad interpreter`.
- **`hooks.json` paths are `${CLAUDE_PLUGIN_ROOT}`-relative.** Never `~/.claude/`. Commands
  already run under `"shell": "bash"`, so don't prefix `bash` — it spawns a nested shell.
- **Don't ship personal config.** No absolute paths, no `enabledPlugins`, no model choice.
  `/setup` merges preferences into the user's `settings.json` with a diff and a prompt; a plugin
  cannot set those keys itself.

## Verifying a change

```bash
bash tests/suite.sh   # exit 0 means every assertion passed
```

## CI

GitHub Actions — `.github/workflows/test.yml`, on push to `main`, on every PR, and on demand.
Runs this suite on **ubuntu-latest and windows-latest**, plus a CRLF check on `*.sh`. Match a run
by SHA: `gh run list -c <sha> -L 5`.

Both platforms deliberately. This plugin exists largely because Windows breaks assumptions Unix
tooling makes — a `python3` that is a Store stub, a CRLF checkout that kills a shebang, a BOM
that hides a healthy config — and every one is invisible on ubuntu. A green ubuntu run proves the
logic; only the Windows leg proves the plugin. Run the suite locally before pushing anyway.

Roughly 4s per assertion on Windows, since each spawns bash plus an interpreter.

**Add a case for anything you change.** Traps worth knowing before you write one:

- **Never put a literal destructive string in a test file.** `guard.sh` inspects the text of the
  command that invokes it, so a literal `rm -rf /` blocks the test run itself. Assemble such
  fixtures at runtime.
- **Never write a literal value-shaped secret either.** `guard.sh` scans the staged diff on
  commit, so a real-looking `key = "..."` in a fixture blocks the commit that adds it.
- **Redirect stdin from `/dev/null`.** `session-start.py` drains stdin, so a test that runs it
  without an EOF hangs rather than failing.
- **Don't assert against a reimplementation of the thing you're testing** — an assertion that
  recomputes `notify.sh`'s sanitizer stays green after the sanitizer is deleted. Drive the script
  and inspect what it produced. **And assert against the consumer's contract, not the producer's
  output**: `json_ok` once asserted the exact key `session-start.py` emitted, so it certified a
  hook whose core never loaded. Driving the real script is necessary and not sufficient.
- **Guard `mktemp`, and stay inside it.** `TMP=$(mktemp -d) && cp ...` does not stop the script;
  a later `> "$TMP/x"` with an empty `TMP` writes to `/x`. And `$TMP/../thing` is the shared temp
  root, not a private path — two suites running at once collide there.
- **Strip ANSI before matching status-line output.** Every value carries its own colour escape,
  so a label and its number are never adjacent in the raw bytes.
- **Use synthetic payload values, never a real model id** — a fixture carrying one reads as a
  claim about which models exist, then quietly stops testing anything when naming changes.

## Docs

**The whole `Docs/` tree is gitignored — `/Docs/`, root-anchored, subfolders included**, so a
subfolder invented later is covered without anyone remembering a `.gitignore` edit. The tree is
working evidence and some of it is private. Committing it is a legitimate choice, but it must be
written into *that* project's `CLAUDE.md` under a `Docs policy` heading, or the next session
re-adds the line. This is the shipped default: `project-docs` owns the rule, `/setup` writes it
on a blank slate and offers it as a choice on an existing repo, and both templates repeat it.

Two ignore traps, both verified with `git check-ignore -v`. The anchor matters: bare `Docs/` also
swallows a nested `packages/*/Docs/`. And `core.ignorecase=true` is the default on Windows and
macOS, so `/Docs/` matches lowercase `docs/` too — anchoring does **not** save you — silently
ignoring a published mkdocs/Docusaurus site. Hence `assets/templates/Docs-skeleton/`: name it
`Docs/` and the plugin stops shipping its own templates.

This repo's tree is `Docs/Audit/`, and it is the only one. Trio promotes finished runs there —
`codex/<date>/` is what Codex reported, `claude/<date>/` is the adjudication. Worth keeping
because an audit's *refutations* are what git history loses: a commit shows what changed, not
which findings were argued down and why.

Two quirks when reading one. Trio's top-level `findings` reads `0` on a `ceiling_reached` run
even when that pass's lenses reported plenty — check `.trio/runs/<id>/pass-N/reconcile.json`, not
the summary. And a `response.json` written after the run ended is never ingested, so the
generated `claude/` file lists everything as open; correct it by hand before promoting.

`CHANGELOG.md` is the exception: a changelog is read by people who don't have your working copy,
so it lives at the **repo root**, committed, never under the gitignored `Docs/`.
