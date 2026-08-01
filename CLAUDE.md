# my-claude-setup

> This is the plugin's *own* project file — conventions for working **on** this repo.
> It is not the config the plugin ships. That lives in `hooks/session-start.py` and `skills/`.

## Project

A Claude Code plugin. It injects a small always-resident rule core, loads seven protocol
references on demand, and enforces four safety hooks. Published as its own marketplace.

## Key files

- `hooks/session-start.py` — the resident core. **This is the file that replaced `CLAUDE.md`.**
  Every token here is paid on every session, so additions need to earn their place.
- `hooks/session-start.sh` — dispatcher with the no-Python fallback. Edit both when the core changes.
- `hooks/guard.sh` — all PreToolUse blocking. One script, dispatches on which field is present.
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

No test suite. Verify hooks by executing them:

```bash
cd hooks
bash session-start.sh | bash py.sh -c "import json,sys; json.load(sys.stdin); print('ok')"
bash brevity.sh
printf '%s' '{"tool_input":{"command":"rm -rf /"}}' | bash guard.sh; echo "exit=$?"   # expect 2
printf '%s' '{"tool_input":{"file_path":"/x/a.ts"}}' | bash guard.sh; echo "exit=$?"  # expect 0
```

Force the fallback branch by pointing `session-start.sh` at a `py.sh` that exits 1 — a missing
interpreter must still emit the reduced core, never nothing.

## Docs

This repo does not keep a `Docs/` tree. It is small enough that git history is the record, and
`Docs/Plan/` is for in-flight work — nothing here stays in flight. The `project-docs` skill and
`assets/templates/` describe the convention for *consuming* projects, not for this one.
