---
description: Merge this plugin's recommended settings into ~/.claude/settings.json, showing the diff first
---

Plugins cannot set `settings.json` keys, so this command does it explicitly and visibly.

1. Read `~/.claude/settings.json`. If it doesn't exist, treat it as `{}`.
2. Compute the merge below. **Only add or change the keys listed** — never remove or reorder
   anything else the user has, and never touch `enabledPlugins` or `extraKnownMarketplaces`.
3. Show the user a diff of exactly what would change. If nothing would change, say so and stop —
   this command must be idempotent.
4. Ask for confirmation. Only then write.

## Keys to merge

| Key | Value | Why |
|-|-|-|
| `env.CLAUDE_CODE_SUBAGENT_MODEL` | `"sonnet"` | Sub-agents run faster and cheaper on Sonnet |
| `permissions.defaultMode` | `"auto"` | |
| `permissions.allow` | union with `["Bash(git:*)", "Bash(ls:*)", "Bash(npm:*)", "Bash(pnpm:*)", "Bash(python:*)", "Bash(xargs grep:*)"]` | Fewer confirmation prompts on the commands a normal session runs constantly. **Read the note below before accepting.** |
| `effortLevel` | `"high"` | |
| `statusLine.command` | `"ccstatusline"` | See the status line step below. The global binary — never an absolute path to a node script, which breaks on every other machine |

Do **not** set `model` — leave the user's choice alone.

### About `Bash(npm:*)` and `Bash(python:*)`

Be straight with the user about these two rather than presenting the whole list as
"least-privilege". `npm run <anything>` executes whatever the project's `package.json` defines,
and `python:*` runs arbitrary code — so allowlisting them is a real widening, and it is worth
the most in exactly the repo where it is riskiest: one whose scripts you did not write.

They are in the default because a Node or Python session prompts constantly without them, and
prompt fatigue causes worse decisions than the widening does. That is a judgment, not a
security argument. If the user works mainly in untrusted or unfamiliar repos, tell them to drop
those two entries and keep the rest — the merge is per-key, so removing them costs nothing else.

`guard.sh` still blocks destructive commands regardless of this list; the allowlist controls
confirmation prompts, not the safety hooks.

Do **not** add `MAX_THINKING_TOKENS`, `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`, or
`CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING`. They have no effect on Claude 5 models; shipping them
teaches people to cargo-cult dead config.

Do **not** add a `hooks` block. This plugin's hooks are declared in its own `hooks/hooks.json`
and are active as soon as the plugin is enabled. A hook copied into `settings.json` would run
twice.

## Status line

Do this as an explicit step, not a footnote. The earlier version of this command only set
`statusLine.command` when `ccstatusline` was *already* on PATH — which on a new machine it never
is, so the key was never written and the config this plugin ships was never installed. Nothing
was broken; it just silently did nothing, forever.

1. Check PATH: `command -v ccstatusline`.
2. **Already installed** → include `statusLine.command` in the merge diff above like any other key.
3. **Not installed** → ask whether they want it. Describe it in one line (a configurable status
   line showing model, context use, git branch, and token cost). If they say no, skip the key
   entirely and don't ask again this session.
4. If they say yes: run `npm install -g ccstatusline`, confirm with `command -v ccstatusline`,
   then include the key in the merge. If npm is missing or the install fails, say so and skip the
   key — never write a `statusLine.command` that isn't on PATH, which produces a broken status
   line on every subsequent launch.
5. Then offer the shipped starting config: copy
   `${CLAUDE_PLUGIN_ROOT}/assets/ccstatusline-settings.json` to
   `~/.config/ccstatusline/settings.json`. **Never overwrite an existing file there** — if one
   exists, say so, show what differs, and leave theirs alone unless they ask.
