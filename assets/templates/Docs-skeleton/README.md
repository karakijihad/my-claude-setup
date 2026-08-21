# Docs — Project Records

Append-only. Newest first in every file. **Only what git cannot reconstruct** — it already
records what changed and when, so anything restating that is cost without value.

| Folder                     | Contents                                                    |
| -------------------------- | ----------------------------------------------------------- |
| [Decisions/](./Decisions/) | Why, and what was rejected — one file per day                |
| [Audit/](./Audit/)         | Review findings **and** their adjudication — `claude/`, `codex/` |
| [Plan/](./Plan/)           | In-flight work only; delete a plan when its work lands       |

Two files may sit beside them: `Plan/BACKLOG.md` (identified, not yet planned) and
`CODEMAP.md` (a structural map, for a repo too large to hold in one head — roles not
histories, and it carries its own regeneration trigger).

**This tree is gitignored by default** — all of it, including any subfolder added later. It is
working evidence, and some of it is private. To version it instead, say so in the project's
`CLAUDE.md` under a `Docs policy` heading; a note left in here is read by nobody.

The release-facing changelog is `CHANGELOG.md` at the **repo root**, not here — it needs to
be readable by people who don't have your working copy, which a tree that ships to no one
cannot do.

There is no fourth folder. A project that must deviate from a protocol says so in its own
`CLAUDE.md`, which is loaded every session — a folder of overrides is loaded by nobody.

See the `project-docs` skill for rules and rationale.
