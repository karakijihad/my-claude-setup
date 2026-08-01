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
| `permissions.allow` | union with `["Bash(git:*)", "Bash(ls:*)", "Bash(npm:*)", "Bash(pnpm:*)", "Bash(python:*)", "Bash(xargs grep:*)"]` | Least-privilege allowlist per `security-protocol` §7.2 |
| `effortLevel` | `"high"` | |
| `statusLine.command` | `"ccstatusline"` | Only if `ccstatusline` is on PATH. The global binary — never an absolute path to a node script, which breaks on every other machine |

Do **not** set `model` — leave the user's choice alone.

Do **not** add `MAX_THINKING_TOKENS`, `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`, or
`CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING`. They have no effect on Claude 5 models; shipping them
teaches people to cargo-cult dead config.

Do **not** add a `hooks` block. This plugin's hooks are declared in its own `hooks/hooks.json`
and are active as soon as the plugin is enabled. A hook copied into `settings.json` would run
twice.

## Optional

If the user wants the status line, mention: `npm install -g ccstatusline`, and that a starting
config is at `${CLAUDE_PLUGIN_ROOT}/assets/ccstatusline-settings.json` which they can copy to
`~/.config/ccstatusline/settings.json`. Don't copy it for them unless asked.
