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

# Show the notice across a few sessions rather than exactly once.
#
# SessionStart context arrives with no user turn attached, so nothing is said
# until the user types something — and the resident core's brevity rule actively
# discourages opening with a multi-line block. Burning the marker on first emit
# therefore loses the notice outright whenever it isn't acted on, which is the
# common case, not the edge case. A small counter costs one repeat at worst.
MAX_SHOWS = 3


def _shown() -> int:
    """How many times the notice has been emitted. MAX_SHOWS means 'done'."""
    try:
        raw = MARKER.read_text(encoding="utf-8-sig").strip()
    except OSError:
        return 0
    if not raw:
        return MAX_SHOWS  # pre-counter marker: that user finished onboarding
    try:
        return int(json.loads(raw).get("shown", MAX_SHOWS))
    except Exception:
        return MAX_SHOWS


def _record(n: int) -> None:
    try:
        MARKER.parent.mkdir(parents=True, exist_ok=True)
        MARKER.write_text(json.dumps({"shown": n}), encoding="utf-8")
    except OSError:
        pass  # unwritable home: surface the notice anyway, accept a repeat

# Keep this list and the companion sentence at the end of core.md in step — they
# name the same set, and they had already drifted apart once. Second element is
# the marketplace, because not every companion ships in the official one.
OFFICIAL = "claude-plugins-official"
# (why, marketplace, marketplace source). Source is None when the marketplace is
# already known to every install; anything else needs `/plugin marketplace add`
# with a real argument, so carry it rather than emitting a <url> placeholder the
# user cannot act on.
COMPANIONS = {
    "feature-dev": ("the Tier-2 reviewer the escalation ladder names", OFFICIAL, None),
    "superpowers": ("process on larger tasks — brainstorming, plans, TDD, verification", OFFICIAL, None),
    "context7": ("unfamiliar or version-sensitive library APIs", OFFICIAL, None),
    "security-guidance": ("the Tier-3 security pass", OFFICIAL, None),
    "code-review": ("GitHub PR review", OFFICIAL, None),
    "code-simplifier": ("opt-in cleanup before the reviewer", OFFICIAL, None),
    "playwright": ("verifying changed interactive or rendering behaviour", OFFICIAL, None),
    "trio": ("the Tier-3 independent audit", "trio-cc", "karakijihad/trio-cc"),
}

# Scripts this config used to install into ~/.claude/hooks/. Only these are
# superseded by hooks/hooks.json — that directory is also where users keep their
# own hooks, and those are none of this plugin's business.
LEGACY_HOOK_SCRIPTS = (
    "block-destructive.sh",
    "check-secrets.sh",
    "protect-files.sh",
    "run-tests.sh",
    "format-code.sh",
)

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
    return [(n, why, mkt, src) for n, (why, mkt, src) in COMPANIONS.items() if n not in on]


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

    # Count only hooks naming a script this config used to install. Matching on
    # the directory alone would sweep in the user's own hooks and present them
    # as leftovers to delete — ~/.claude/hooks/ is a normal place to keep them.
    stale = []
    for entries in (cfg.get("hooks") or {}).values():
        for entry in entries or []:
            for h in entry.get("hooks") or []:
                cmd = h.get("command") or ""
                if "~/.claude/hooks/" not in cmd:
                    continue
                for script in LEGACY_HOOK_SCRIPTS:
                    if script in cmd:
                        stale.append(script)
                        break
    if stale:
        names = ", ".join(sorted(set(stale)))
        found.append(
            f"{len(stale)} hook(s) in settings.json still run this config's removed "
            f"scripts ({names}); hooks/hooks.json supersedes them"
        )
    return found


def _compose(missing: list, gaps: list, legacy: list) -> str:
    lines = [
        "",
        "FIRST RUN — my-claude-setup was just installed. Open your very next reply "
        "with this, before answering whatever the user asked: list what is missing "
        "below and offer to walk through it. This is the one message that overrides "
        "the brevity rule — the resident core says no preamble and under 100 words, "
        "and following that here would swallow the notice entirely. Do not run "
        "anything without their agreement. Say that it stops appearing once they "
        "are set up.",
    ]
    if missing:
        lines.append("Companion plugins not enabled (nothing hard-fails without them):")
        lines += [f"  - {n} — {why}" for n, why, _, _ in missing]
        lines.append("  Install with:")
        for n, _, mkt, src in missing:
            if src:
                lines.append(f"    /plugin marketplace add {src}")
            lines.append(f"    /plugin install {n}@{mkt}")
    if gaps:
        lines.append("Recommended settings not applied (" + "; ".join(gaps) + "). Offer /setup.")
    if legacy:
        lines.append("Leftovers from the old symlink install:")
        lines += [f"  - {x}" for x in legacy]
        lines.append(
            "  Offer to remove them, listing each path first. Never touch settings.json, "
            "and never delete a real file or directory — only links into an old clone."
        )
    return "\n".join(lines)


def notice() -> str:
    """Return the onboarding block, or '' once there is nothing left to say."""
    try:
        seen = _shown()
        if seen >= MAX_SHOWS:
            return ""
        cfg = _settings()
        missing, gaps, legacy = _missing_companions(cfg), _unapplied_settings(cfg), _legacy_artifacts(cfg)
        if not (missing or gaps or legacy):
            # Fully set up. Stop permanently, not just this session.
            _record(MAX_SHOWS)
            return ""
        _record(seen + 1)
        return _compose(missing, gaps, legacy)
    except Exception:
        return ""
