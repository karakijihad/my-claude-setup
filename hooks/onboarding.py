"""First-run detection for the SessionStart hook.

Claude Code has no install-time hook event — nothing fires when a plugin is
added — so onboarding has to ride on the first session after install. This
inspects what is actually missing rather than printing a fixed banner, then
never speaks again.

Everything here is best-effort. A detection failure must never cost the user
their resident rules, so `notice()` swallows its own errors.
"""
import json
import os
from pathlib import Path

MARKER = Path.home() / ".claude" / ".my-claude-setup-onboarded"
SETTINGS = Path.home() / ".claude" / "settings.json"

COMPANIONS = {
    "feature-dev": "the code-reviewer agent the independent-review rule names",
    "superpowers": "brainstorming, plans, TDD, verification",
    "context7": "live library docs instead of model memory",
    "security-guidance": "the security-protocol review gate",
    "code-review": "the git-protocol PR process",
    "code-simplifier": "the simplify step",
    "playwright": "the verification level for any UI change",
}

# Legacy symlink install: directories that were linked into ~/.claude.
LEGACY_DIRS = ("Docs", "hooks", "Templates")


def _settings() -> dict:
    # utf-8-sig, not utf-8: Windows tooling writes a BOM (PowerShell's
    # Set-Content -Encoding utf8 always does), and json.loads rejects it.
    # Reading it as plain utf-8 makes a healthy config look entirely absent,
    # which would make onboarding nag a user who has everything set up.
    try:
        return json.loads(SETTINGS.read_text(encoding="utf-8-sig"))
    except Exception:
        return {}


def _missing_companions(cfg: dict) -> list:
    enabled = cfg.get("enabledPlugins") or {}
    on = {k.split("@")[0] for k, v in enabled.items() if v}
    return [(n, why) for n, why in COMPANIONS.items() if n not in on]


def _unapplied_settings(cfg: dict) -> list:
    gaps = []
    if not (cfg.get("env") or {}).get("CLAUDE_CODE_SUBAGENT_MODEL"):
        gaps.append("no CLAUDE_CODE_SUBAGENT_MODEL")
    if not (cfg.get("permissions") or {}).get("allow"):
        gaps.append("no permissions.allow entries")
    return gaps


def _legacy_artifacts(cfg: dict) -> list:
    found = []
    base = Path.home() / ".claude"
    for name in LEGACY_DIRS:
        p = base / name
        try:
            if p.exists() or p.is_symlink():
                found.append(f"~/.claude/{name}/ still present")
        except OSError:
            pass
    if (base / "CLAUDE.md").exists():
        found.append("~/.claude/CLAUDE.md still present — it doubles these rules")

    dead = 0
    for entries in (cfg.get("hooks") or {}).values():
        for entry in entries or []:
            for h in entry.get("hooks") or []:
                if "~/.claude/hooks/" in (h.get("command") or ""):
                    dead += 1
    if dead:
        found.append(f"{dead} hook(s) in settings.json point at ~/.claude/hooks/, which no longer exists")
    return found


def _compose(missing: list, gaps: list, legacy: list) -> str:
    lines = [
        "",
        "FIRST RUN — my-claude-setup was just installed. Tell the user what is "
        "missing below and offer to walk through it. Do not run anything without "
        "their agreement. Mention this appears once.",
    ]
    if missing:
        lines.append("Companion plugins not enabled (nothing hard-fails without them):")
        lines += [f"  - {n} — {why}" for n, why in missing]
        lines.append("  Install with:")
        lines += [f"    /plugin install {n}@claude-plugins-official" for n, _ in missing]
    if gaps:
        lines.append("Recommended settings not applied (" + "; ".join(gaps) + "). Offer /setup.")
    if legacy:
        lines.append("Leftovers from the old symlink install:")
        lines += [f"  - {x}" for x in legacy]
        lines.append("  Offer /unlink-legacy, which identifies everything before removing anything.")
    return "\n".join(lines)


def notice() -> str:
    """Return the one-time onboarding block, or '' if there is nothing to say."""
    try:
        if MARKER.exists():
            return ""
        cfg = _settings()
        missing, gaps, legacy = _missing_companions(cfg), _unapplied_settings(cfg), _legacy_artifacts(cfg)
        try:
            MARKER.parent.mkdir(parents=True, exist_ok=True)
            MARKER.write_text("", encoding="utf-8")
        except OSError:
            pass  # unwritable home: surface the notice anyway, accept a repeat
        if not (missing or gaps or legacy):
            return ""
        return _compose(missing, gaps, legacy)
    except Exception:
        return ""
