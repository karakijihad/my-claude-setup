---
description: Find and remove the old symlink-based installation of this config from ~/.claude
---

Earlier versions of this config were installed by symlinking files and directories from a clone
into `~/.claude/`. The plugin replaces all of it. This command removes the leftovers.

**This command deletes files. Identify everything first, show the user the full list, and get
confirmation before removing anything. Never delete something you have not listed.**

## 1. Find

Report each of these with its type (symlink/junction → target, or real file/directory):

- `~/.claude/CLAUDE.md`, `~/.claude/settings.json`
- `~/.claude/Docs/`, `~/.claude/hooks/`, `~/.claude/Templates/`
- Entries under `~/.claude/skills/` — check each for `dependency-auditor`, `pr-review-expert`,
  `skill-security-auditor`
- `~/.claude/settings.json.bak`, `.orig`, `.pre-symlink`
- `~/.claude/hooks/__pycache__/`
- `~/.config/ccstatusline` if it is a link into the clone

## 2. Classify

- **Reparse point (symlink/junction) pointing into a clone of this repo** → safe to remove; the
  plugin supersedes it.
- **Real file or directory** → do NOT delete. It is the user's own content, or a copy that has
  drifted from the repo. Report it and ask what they want. `skill-security-auditor` in
  particular is often a real copy rather than a link.
- **`settings.json`** → never delete. Two separate things to check:
  - If it is a symlink into the clone, it must become a real file first — copy the target's
    contents in place — or Claude Code loses its settings when the clone goes. Offer to do that.
  - Read its `hooks` block. Old installs wired hooks by absolute path, e.g.
    `bash ~/.claude/hooks/block-destructive.sh`. Those scripts no longer exist, so every
    matching tool call now fails its hook — exit 127, noisy but non-blocking. This plugin
    declares its own hooks in `hooks/hooks.json`, so any entry pointing into `~/.claude/hooks/`
    is dead weight. Show the user the exact entries and get confirmation before removing them.
    Leave every other hook alone, including any tagged `ccstatusline-managed`.
- **`CLAUDE.md`** → if it is the old global config this plugin replaced, it is now redundant
  with the session-start hook and will double the rules. Confirm the plugin is installed and
  its core is being injected, then offer to remove it.
- Anything unrecognised → leave it and report it.

## 3. Remove

Only after explicit confirmation, and only the reparse points. Remove the link, never follow it
and delete the target — the target is the user's git clone.

## 4. Report

State what was removed, what was left and why, and remind the user to restart Claude Code so the
plugin's hooks take over.
