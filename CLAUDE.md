# my-claude-setup

> Conventions for working **on** this repo. Not the config the plugin ships — that lives in
> `hooks/core.md` and `skills/`.
>
> Rules and traps only. Every "why" is in `CHANGELOG.md` and belongs there, not here. This file
> loads into every session in this repo, so a paragraph of history costs more than it teaches.

## Project

A Claude Code plugin. A small always-resident rule core, six protocol skills loaded on demand,
five hooks, two agents, one command. Published as its own marketplace.

It sets a rail — how to plan, when to fan out, which companion owns which decision, what a
review must clear — and it is not a place to carry expertise a companion already owns. Growth
here is the failure mode: the security curriculum, the testing curriculum and a subagent report
gate were all deleted for it.

## Key files

| Path | The rule |
|---|---|
| `hooks/core.md` | The resident core, and the only copy of it. Paid every session — additions must earn it. |
| `hooks/session-start.py` | Wraps the core with git context and notices. The reviewer notice is conditional on `enabledPlugins`: a review that never happened must not read like one that did. |
| `hooks/session-start.sh` | Dispatcher. Two fallbacks; the last (no Python *and* no jq) restates policy deliberately reduced, never mirrored. |
| `hooks/guard.sh` | All PreToolUse blocking. Dispatches on which field is present. |
| `hooks/budget.sh` | Doc line budgets. **The ratchet is the design** — warn once, again only if an edit worsens it. A hook that re-warns on the corrective edit gets ignored. Keyed on file *names*, which is why `project-docs` makes `INDEX.md` and `phase-*.md` normative. |
| `hooks/post-push.sh` | CI reminder. Fires on every Bash/PowerShell call, so rejections are ordered cheapest-first. Names the SHA and points at the repo's `## CI` line; it does **not** detect providers or claim a push landed, and is silent for a `-C` push at another repo. Exit 0 always — PostToolUse cannot block. |
| `hooks/context-watch.sh` | PostToolBatch. Injects the session's context fill once per 5% crossing, escalating past a budget. Reads the state file `statusline.mjs` writes — no hook payload carries `context_window`. Silent for subagents. Exit 0 always. |
| `hooks/onboarding.py` | One-time first-run check. Must never nag a user already set up. Reads settings as **`utf-8-sig`** — a BOM makes a healthy config look absent. |
| `hooks/selfheal.py` | The update path. Python does what is deterministic; the session does what needs judgement. Never overwrites a user's value. **The diff runs before the prune.** |
| `hooks/py.sh` | Interpreter resolver. Every Python entry point goes through it. |
| `assets/statusline-launcher.mjs` | The stable path `settings.json` points at. The plugin's own directory is version-pinned, and pointing there fails *silently* — old versions stay cached, so the bar renders from a dead release. |
| `assets/statusline.mjs` | The status line, and the only component the harness hands `context_window` to. Writes the context state file as a side effect. |
| `skills/*/SKILL.md` | The `description:` is the router (see Gotchas). Resident in **every** session — budget like `core.md`, ~30–70 tokens, naming trigger situations rather than topic vocabulary. A skill holds what *this setup decides differently*; generic best practice is the model's job already. |
| `skills/security-protocol/` | Escalation and agent/MCP tool authority only. The ten reference files were deleted: `core.md` assigns security expertise to the `security-guidance` companion, and shipping both was the plugin breaking its own one-job rule. |
| `agents/` | `worker` and `advisor`. **They exist for `effort: high`** — the Agent tool passes `model` but not effort, so a definition is the only place to set it. Model stays off both cards so a call-site model wins. |
| `tests/suite.sh` | The whole suite. Outside `hooks/` because `hooks/` is what ships; still `cd`s there. |
| `.claude-plugin/` | Bump `version` on release, add the `CHANGELOG.md` section in the same commit. |

## Gotchas

- **Never invoke `python3` directly** — anywhere. On Windows it is usually a 0-byte Store alias
  that exits 9009, and installing Python does not displace it. Route through `hooks/py.sh`.
- **Hooks fail open.** A hook that errors exits 0. Exit 2 blocks the call, and `guard.sh` is now
  the only sanctioned use. `subagent-verify.sh` was the other and is gone: it could check that a
  report's text *looked* like evidence, never that a command ran, so it bought the feeling of a
  gate. The report contract is prose in `agent-protocol`; the orchestrator is the check.
- **Match the harness's JSON contract exactly.** Output is read from
  `hookSpecificOutput.additionalContext` **with `hookEventName` set**. Anything else — including a
  bare top-level `additionalContext`, the SDK shape — is discarded silently: valid JSON, exit 0,
  nothing injected, nothing logged. Emit exactly one shape; hedging double-injects.
- **A skill's `description:` is the routing mechanism.** If a protocol stops firing, fix the
  description — don't add a hook.
- **`*.sh` must stay LF.** `.gitattributes` pins it; CRLF kills the shebang.
- **`hooks.json` paths are `${CLAUDE_PLUGIN_ROOT}`-relative**, never `~/.claude/`. Commands already
  run under `"shell": "bash"` — don't prefix `bash`.
- **Don't ship personal config.** No absolute paths, no `enabledPlugins`, no model choice.

## Verifying a change

```bash
bash tests/suite.sh context-watch   # one section, ~60s — use this while iterating
bash tests/suite.sh                 # all sections; exit 0 means every assertion passed
```

A full run takes minutes because process spawn dominates on Windows — `bash -c true` alone can
cost over a second under on-launch AV scanning. The suite takes an atomic lock, so a second
concurrent run refuses rather than colliding in the shared temp root.

## Tests

**What earns a test:** what plausible defect would make it fail, what would that defect cost, and
does an existing test already catch it? A describable scenario is not a reason by itself. Reuse or
replace a case before adding one. `testing-protocol` holds the three classes and how hard to hold
each — safety keeps everything, contracts get one case per path, advisory gets four.

**The suite is held to that, and the advisory sections are the ones that grow.** It was 2,241
lines and 192 cases before the 1.24.0 prune; anything approaching that again means advisory
permutations have crept back. Cut those first and safety never.

Traps, all learned the hard way:

- **Never put a literal destructive string in a test file** — `guard.sh` inspects the command that
  invokes it, so the literal blocks the test run. Assemble it at runtime. Same for value-shaped
  secrets: `guard.sh` scans the staged diff on commit.
- **Redirect stdin from `/dev/null`** — `session-start.py` drains stdin and will hang otherwise.
- **Don't assert against a reimplementation of the thing you're testing.** Drive the real script
  and inspect what it produced. **And assert the consumer's contract, not the producer's output** —
  `json_ok` once certified a hook whose core never loaded.
- **Guard `mktemp`, and stay inside it.** `TMP=$(mktemp -d) && cp ...` does not stop the script,
  and `$TMP/../thing` is the shared temp root, not a private path.
- **Strip ANSI before matching status-line output** — every value carries its own escape, so a
  label and its number are never adjacent in the raw bytes.
- **Use synthetic payload values, never a real model id.**

## CI

GitHub Actions — `.github/workflows/test.yml`, on push to `main`, on PRs, on demand. Runs the
suite on **ubuntu-latest and windows-latest** plus a CRLF check on `*.sh`. Match a run by SHA:
`gh run list -c <sha> -L 5`.

Both platforms deliberately. This plugin exists largely because Windows breaks Unix assumptions —
a Store-stub `python3`, a CRLF checkout, a BOM hiding a config — and every one is invisible on
ubuntu. A green ubuntu run proves the logic; only Windows proves the plugin.

## Docs

**The whole `Docs/` tree is gitignored — `/Docs/`, root-anchored, subfolders included.** It is
working evidence and some of it is private. Committing it is a legitimate choice, but it must be
written into *that* project's `CLAUDE.md` under a `Docs policy` heading, or the next session
re-adds the line.

Two ignore traps, both verified with `git check-ignore -v`. The anchor matters: bare `Docs/` also
swallows a nested `packages/*/Docs/`. And `core.ignorecase=true` is the default on Windows and
macOS, so `/Docs/` matches lowercase `docs/` too — anchoring does **not** save you. Hence
`assets/templates/Docs-skeleton/`: name it `Docs/` and the plugin stops shipping its own templates.

This repo's tree is `Docs/Audit/` — `codex/<date>/` is what Codex reported, `claude/<date>/` the
adjudication. Worth keeping because an audit's *refutations* are what git history loses.

Two quirks when reading one: Trio's top-level `findings` reads `0` on a `ceiling_reached` run, so
check `.trio/runs/<id>/pass-N/reconcile.json` instead. And a `response.json` written after the run
ended is never ingested, so the generated `claude/` file lists everything as open — correct it by
hand before promoting.

`CHANGELOG.md` is the exception — read by people without your working copy, so it lives at the
**repo root**, committed, never under the gitignored `Docs/`.
