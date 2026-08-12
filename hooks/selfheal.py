#!/usr/bin/env python
"""Repair the plugin's own wiring after an update, then say what changed.

A plugin that needs a command run by hand after every release is a plugin that
is broken on most machines most of the time — nobody remembers, and the failures
are quiet. So this runs on SessionStart, notices when the installed version has
moved, fixes what the plugin owns, and reports it in the same breath.

What it repairs, and only this:

  * `~/.claude/statusline.mjs` — refreshed from the release that is actually
    installed, so improvements to the launcher ship with the plugin.
  * `settings.json` -> `statusLine.command` — repointed at that stable path if
    it still names a versioned path inside the plugin cache.

Deliberately narrow. It rewrites a key this plugin wrote, to a value this plugin
owns, and touches nothing a user chose. It will not add keys, enable plugins, or
change a status line pointing at somebody else's script — a hook that edits
settings the user did not delegate is worse than a stale path.

Every failure is swallowed and reported as "nothing happened". The core rules
matter more than the repair, and a session that will not start because a
convenience threw is a bad trade.
"""
import io
import json
import os
import shutil
from pathlib import Path

PLUGIN = "my-claude-setup"
HOME = Path.home()
CLAUDE = HOME / ".claude"
# Records the version this last healed for. Its absence means "never healed",
# which on an existing install is exactly when the repair is most needed.
STAMP = CLAUDE / ".my-claude-setup-version"
LAUNCHER_DEST = CLAUDE / "statusline.mjs"


def _read_json(path):
    # utf-8-sig: Windows tooling writes a BOM, and plain utf-8 makes a healthy
    # file look like a broken one. Same reason onboarding.py reads settings so.
    with io.open(path, encoding="utf-8-sig") as fh:
        return json.load(fh)


def installed() -> tuple:
    """(version, installPath) for this plugin, from Claude Code's own manifest."""
    data = _read_json(CLAUDE / "plugins" / "installed_plugins.json")
    for key, entries in data.get("plugins", {}).items():
        if key.split("@")[0] != PLUGIN:
            continue
        for entry in entries:
            path = entry.get("installPath")
            if path and os.path.isdir(path):
                return entry.get("version", "unknown"), path
    return None, None


def _stamped() -> str:
    try:
        return STAMP.read_text(encoding="utf-8").strip()
    except Exception:
        return ""


def _statusline_needs_repointing(cfg: dict) -> bool:
    """True only when statusLine names a path inside this plugin's cache.

    A user pointing at their own script, or at nothing, is left alone. The
    versioned path is the failure being fixed: Claude Code keeps every previous
    release on disk, so a stale one still resolves and still runs, and the bar
    renders from a version nobody is using with nothing to indicate it.
    """
    cmd = (cfg.get("statusLine") or {}).get("command") or ""
    return PLUGIN in cmd and str(LAUNCHER_DEST).replace("\\", "/") not in cmd.replace("\\", "/")


def heal() -> str:
    """Repair if the version moved. Returns a notice, or "" when silent."""
    try:
        version, root = installed()
        if not version:
            return ""
        if version == _stamped():
            return ""  # already healed for this release — the common path

        done = []

        src = Path(root) / "assets" / "statusline-launcher.mjs"
        if src.is_file():
            fresh = not LAUNCHER_DEST.is_file() or (
                src.read_bytes() != LAUNCHER_DEST.read_bytes()
            )
            if fresh:
                LAUNCHER_DEST.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(src, LAUNCHER_DEST)
                done.append("refreshed the status-line launcher at ~/.claude/statusline.mjs")

            settings = CLAUDE / "settings.json"
            try:
                cfg = _read_json(settings)
            except Exception:
                cfg = None
            if cfg is not None and _statusline_needs_repointing(cfg):
                cfg["statusLine"] = {
                    "type": "command",
                    "command": 'node "%s"' % str(LAUNCHER_DEST).replace("\\", "/"),
                    "padding": (cfg.get("statusLine") or {}).get("padding", 0),
                }
                io.open(settings, "w", encoding="utf-8").write(
                    json.dumps(cfg, indent=2, ensure_ascii=False) + "\n"
                )
                done.append(
                    "repointed statusLine at that launcher, so it follows future "
                    "updates instead of pinning to one release"
                )

        STAMP.write_text(version, encoding="utf-8")

        if not done:
            return ""
        return (
            "\n\n<my-claude-setup-updated>\nThe plugin updated to %s and repaired its own "
            "wiring:\n- %s\n\nTell the user this happened, in one line, the first time they "
            "say anything. Nothing is required of them.\n</my-claude-setup-updated>"
            % (version, "\n- ".join(done))
        )
    except Exception:
        # A repair that breaks the session it was meant to improve is a net loss.
        return ""
