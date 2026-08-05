# Docs — Project Records

Append-only. Newest first in every file. **Only what git cannot reconstruct** — it already
records what changed and when, so anything restating that is cost without value.

| Folder                     | Contents                                                    |
| -------------------------- | ----------------------------------------------------------- |
| [Decisions/](./Decisions/) | Why, and what was rejected — one file per day                |
| [Audit/](./Audit/)         | Review findings **and** their adjudication — `claude/`, `codex/` |
| [Plan/](./Plan/)           | In-flight work only; delete a plan when its work lands       |

The release-facing changelog is `CHANGELOG.md` at the **repo root**, not here — it needs to
be readable by people who don't have your working copy.

Two more trees are available but not scaffolded. Create one the day you need it, not before:

- `Protocols/` — project-specific overrides of a protocol skill. Rare. Name what it overrides.
- `Logs/CODEMAP.md` — structural file map. Generate on demand; a stale CODEMAP is worse than
  none, because it gets believed.

See the `project-docs` skill for rules and rationale.
