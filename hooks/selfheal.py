#!/usr/bin/env python
"""On the first session after an update: repair, report, and re-run setup.

A plugin that needs a command run by hand after every release is broken on most
machines most of the time — nobody remembers, and nothing complains. So this
runs on SessionStart, notices when the installed version has moved, and turns
that into the same work `/setup` Part 1 does, without anyone having to ask.

The split is deliberate, and it is the whole design:

  * **Python does what is deterministic.** Refresh the launcher, repoint a
    `statusLine` still pinned to a versioned path, diff the outgoing release
    against the incoming one, delete the versions nothing points at any more.
    No judgement required, so no model required.

  * **The session does what needs judgement.** Merging settings, installing
    companions that joined the roster, and explaining what actually changed are
    decisions, not file operations. This emits an instruction block describing
    exactly what moved; the session carries it out against `/setup` Part 1.

That ordering matters for the diff: the outgoing version has to still be on
disk to compare against, so the summary is computed *before* the prune.

Everything here is wrapped. A repair that breaks the session it was meant to
improve is a net loss, and the resident rules matter more than the repair.
"""
import hashlib
import io
import json
import os
import re
import shutil
from pathlib import Path

PLUGIN = "my-claude-setup"
HOME = Path.home()
CLAUDE = HOME / ".claude"
STAMP = CLAUDE / ".my-claude-setup-version"
LAUNCHER_DEST = CLAUDE / "statusline.mjs"

VERSION_DIR = re.compile(r"^\d+\.\d+\.\d+")
# Enough to say what moved without pasting a release into the context window.
MAX_LISTED = 12


def _read_json(path):
    # utf-8-sig: Windows tooling writes a BOM, and plain utf-8 makes a healthy
    # file look broken. Same reason onboarding.py reads settings this way.
    with io.open(path, encoding="utf-8-sig") as fh:
        return json.load(fh)


def installed():
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


# ── what changed ────────────────────────────────────────────────────────────

def _fingerprint(root: Path) -> dict:
    """relative path -> content hash, for every file in a release."""
    out = {}
    for dirpath, _dirs, files in os.walk(root):
        for name in files:
            full = Path(dirpath) / name
            try:
                rel = full.relative_to(root).as_posix()
                out[rel] = hashlib.sha256(full.read_bytes()).hexdigest()
            except Exception:
                continue
    return out


def _changes(old_root, new_root) -> dict:
    """{'added': [...], 'changed': [...], 'removed': [...]} between two releases."""
    if not old_root or not Path(old_root).is_dir():
        return {}
    a, b = _fingerprint(Path(old_root)), _fingerprint(Path(new_root))
    return {
        "added": sorted(set(b) - set(a)),
        "removed": sorted(set(a) - set(b)),
        "changed": sorted(p for p in set(a) & set(b) if a[p] != b[p]),
    }


def _summarise(ch: dict) -> str:
    """Group the diff the way a reader thinks about it, not by directory depth."""
    if not ch or not any(ch.values()):
        return ""
    buckets = [
        ("resident rules", lambda p: p == "hooks/core.md"),
        ("protocols and skills", lambda p: p.startswith("skills/")),
        ("commands", lambda p: p.startswith("commands/")),
        ("hooks", lambda p: p.startswith("hooks/") and p != "hooks/core.md"),
        ("status line", lambda p: "statusline" in p),
        ("templates and assets", lambda p: p.startswith("assets/")),
        ("docs", lambda p: p.endswith(".md") and "/" not in p),
    ]
    # First bucket wins. Without this a launcher counts as both "status line"
    # and "templates and assets", and a reader has to work out that the two
    # lines are the same file rather than two changes.
    claimed = set()
    lines = []
    for label, match in buckets:
        hits = []
        for kind in ("changed", "added", "removed"):
            for p in ch.get(kind, []):
                if p in claimed or not match(p):
                    continue
                claimed.add(p)
                hits.append("%s (%s)" % (p, kind))
        if not hits:
            continue
        shown = hits[:MAX_LISTED]
        extra = len(hits) - len(shown)
        lines.append(
            "- **%s**: %s%s"
            % (label, ", ".join(shown), " and %d more" % extra if extra else "")
        )
    return "\n".join(lines)


# ── deterministic repairs ───────────────────────────────────────────────────

def _statusline_pinned(cfg: dict) -> bool:
    """True only when statusLine names a path inside this plugin's cache.

    A user pointing at their own script, or at nothing, is left alone.
    """
    cmd = (cfg.get("statusLine") or {}).get("command") or ""
    stable = str(LAUNCHER_DEST).replace("\\", "/")
    return PLUGIN in cmd and stable not in cmd.replace("\\", "/")


def _repair_statusline(root) -> list:
    done = []
    src = Path(root) / "assets" / "statusline-launcher.mjs"
    if not src.is_file():
        return done
    if not LAUNCHER_DEST.is_file() or src.read_bytes() != LAUNCHER_DEST.read_bytes():
        LAUNCHER_DEST.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, LAUNCHER_DEST)
        done.append("refreshed the status-line launcher at `~/.claude/statusline.mjs`")

    settings = CLAUDE / "settings.json"
    try:
        cfg = _read_json(settings)
    except Exception:
        return done
    if _statusline_pinned(cfg):
        cfg["statusLine"] = {
            "type": "command",
            "command": 'node "%s"' % str(LAUNCHER_DEST).replace("\\", "/"),
            "padding": (cfg.get("statusLine") or {}).get("padding", 0),
        }
        io.open(settings, "w", encoding="utf-8").write(
            json.dumps(cfg, indent=2, ensure_ascii=False) + "\n"
        )
        done.append("repointed `statusLine` at that launcher, so it follows future updates")
    return done


def _prune(root, keep: str) -> list:
    """Delete cached releases other than the installed one.

    Claude Code never removes these itself, and before the launcher existed they
    were not merely wasted disk: a `statusLine` pinned to an old path kept
    resolving into one of them, so the bar rendered from a release nobody was
    running and nothing said so.

    Guarded three ways, because this is the one destructive thing here: the
    parent must sit under the plugin cache, the directory name must look like a
    version, and the installed one is never a candidate.
    """
    removed = []
    try:
        base = Path(root).parent
        cache = (CLAUDE / "plugins" / "cache").resolve()
        if cache not in base.resolve().parents:
            return removed
        for child in base.iterdir():
            if child.is_dir() and child.name != keep and VERSION_DIR.match(child.name):
                shutil.rmtree(child, ignore_errors=True)
                if not child.exists():
                    removed.append(child.name)
    except Exception:
        pass
    return removed


# ── entry point ─────────────────────────────────────────────────────────────

def heal() -> str:
    try:
        version, root = installed()
        if not version:
            return ""
        previous = _stamped()
        if version == previous:
            return ""  # the common path: nothing moved, say nothing

        # Diff before pruning — the outgoing release has to still exist.
        old_root = Path(root).parent / previous if previous else None
        summary = _summarise(_changes(old_root, root))

        repairs = _repair_statusline(root)
        pruned = _prune(root, version)
        STAMP.write_text(version, encoding="utf-8")

        head = (
            "The my-claude-setup plugin updated from %s to %s."
            % (previous or "an unrecorded version", version)
        )
        block = ["\n\n<my-claude-setup-updated>", head, ""]
        if summary:
            block += ["**What changed in the plugin:**", summary, ""]
        if repairs:
            block += ["**Already repaired automatically:**"] + ["- " + r for r in repairs] + [""]
        if pruned:
            block += [
                "**Pruned %d superseded cached release%s:** %s. Nothing points at them; "
                "Claude Code does not remove them itself."
                % (len(pruned), "" if len(pruned) == 1 else "s", ", ".join(sorted(pruned))),
                "",
            ]
        block += [
            "**Now finish the update, before anything else this session.** Read "
            "`${CLAUDE_PLUGIN_ROOT}/commands/setup.md` and carry out Part 1 sections 1.1 to "
            "1.5 against the current machine — marketplaces, the companion roster, "
            "`settings.json`, and the companion env tuning. Treat it as reconciliation, not a "
            "fresh install: skip everything already correct, and report only differences.",
            "",
            "Two rules while doing it. **Add missing keys; never overwrite a value the user "
            "already set to something else** — report that as a difference and leave it. And "
            "**ask before installing a companion**: repairing a path this plugin wrote is the "
            "plugin's business, putting new software on someone's machine is theirs.",
            "",
            "Then tell the user, in a few lines: what changed, what was repaired, what was "
            "pruned, and anything still needing their decision. If nothing needs deciding, say "
            "that plainly and move on to what they actually asked for.",
            "</my-claude-setup-updated>",
        ]
        return "\n".join(block)
    except Exception:
        return ""
