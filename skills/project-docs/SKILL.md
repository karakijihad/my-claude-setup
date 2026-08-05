---
name: project-docs
description: >
  The per-project Docs/ convention — decision records, audit evidence, and in-flight plans,
  with line budgets. Use when recording why a decision was made, when writing down what an
  audit found and how it was adjudicated, when opening or updating a plan file, when
  bootstrapping a new project's Docs folder, or when deciding whether a Docs tree is
  committed or kept local.
---

# Per-Project Docs

**Write down what git cannot reconstruct. Nothing else.**

Git already records what changed, when, by whom, and in what order. Documentation that
restates it is pure cost: written once, read many times, stale within a month, and
misleading once stale. Three things survive that test.

```
Docs/
├── Decisions/YYYY-MM-DD.md     why, and what was rejected
├── Audit/
│   ├── claude/YYYY-MM-DD/      the adjudication — verdict per finding
│   └── codex/YYYY-MM-DD/       what the auditor reported
└── Plan/                       in-flight only; delete when the work lands
CHANGELOG.md                    at the repo root, committed, release-facing
```

## Why these three

- **`Decisions/`** — the accepted decision, the constraint that forced it, and *the option
  you rejected*. A diff shows the road taken; nothing in git shows the road refused, and
  that is the thing you re-litigate six months later.
- **`Audit/`** — findings **plus** adjudication. The refutations are the point: a commit
  shows what changed, never which findings were argued down and why. `trio:trio-audit`
  fills both halves — `codex/` is what its lenses reported, `claude/` the verdict per
  finding. Record both by hand when the audit was manual. **An audit is never a decision
  by itself.**
- **`Plan/`** — the only forward-looking tree. It exists so work survives a context reset;
  see `planning-protocol` for its structure. Delete a plan when its work lands — a
  completed plan is history, and git holds history.

**`CHANGELOG.md` lives at the repo root and is committed.** A changelog exists to be read
by people who don't have your working copy, so a dated file inside an ignored `Docs/`
cannot do that job. Group by release, not by day.

## Local by default

**`Docs/` is gitignored** — the whole tree, including subfolders that don't exist yet. One
root-anchored line:

```gitignore
# Project docs — local by default, whole tree including subfolders added later
/Docs/
```

The tree holds working evidence, not a deliverable: findings mid-adjudication, plans that die
when the work lands, decisions still being argued, and whatever else the author drops into a
folder they invented that afternoon. Some of that is private. So the rule names the
**directory**, not its children — otherwise it protects only the folders someone remembered.

Three things to know before adding the line:

- **It does not untrack anything.** Files already committed under `Docs/` stay tracked and keep
  going to the remote. `git ls-files -- Docs` tells you; `git rm --cached -r -- Docs/` is the fix
  and it **deletes them from the remote on the next push**. Never run it unprompted.
- **It is not a privacy remediation.** Anything already pushed is in history and in every clone.
  Ignoring it now changes nothing about that — real exposure means rotating what leaked and a
  deliberate history rewrite, not a `.gitignore` line.
- **On Windows and macOS it also matches `docs/`.** `core.ignorecase=true` is the default on
  those filesystems, and *anchoring does not help* — `/Docs/` still swallows a lowercase `docs/`.
  That is where published doc sites live (mkdocs, Docusaurus). In a repo that has one, run
  `git check-ignore -v docs/<some-file>` first; on a collision the site wins and the project
  records the deviation below.

In a monorepo, give each package's tree its own anchored line (`/packages/foo/Docs/`). Dropping
the anchor would catch them all in one go — and also anything vendored under that name.

**Committing `Docs/` is a legitimate choice. It just has to be written down**, in the project's
`CLAUDE.md`, which is loaded every session:

```md
## Docs policy

`Docs/` is versioned in this repo on purpose. Do not add `/Docs/` to `.gitignore`.
```

A note inside `Docs/` or a comment where the `.gitignore` line *isn't* is read by nobody, and
the next session helpfully re-adds the rule. `/bootstrap-project` and `/repo-fix` both look for
that section before they touch `.gitignore`.

## Three, and only three

There is no fourth tree, and no reserved path for one.

**A project that must deviate from a protocol says so in its own `CLAUDE.md`.** That file is
loaded every session; a folder of overrides is loaded by nobody. A convention with no
mechanism behind it is decoration — it looks like governance and enforces nothing.

**A structural file map is generated when someone asks for one**, not maintained. For a large
repo that's a reasonable thing to want; reserving it a permanent home is how it ends up stale,
and a file map that lags a rename is worse than none, because it gets believed.

If you find yourself wanting a new tree, the question to answer first is what reads it.

## Sizing — highlights, not monoliths

These files exist for *trackability*, not reconstruction. Evidence lives in commits, diffs,
and audits; docs link to it rather than duplicating it.

- **Line budgets live in each template's header** — that header is the single source of
  truth, so don't restate the numbers anywhere else.
- **Decision entry** — Decision (1–2 sentences) · Why, including the triggering incident
  (1–2) · Rejected alternative and what ruled it out (1–2) · Mechanism, file and function
  rather than code (1–2). Longer than that belongs in a plan or audit, linked.
- **Changelog entry** — `Added/Changed/Fixed/Removed`, one line per item. No narrative.

**Reject these:** pasting commit messages verbatim, embedding whole audit findings, a
paragraph per file touched, restating a change under three headings, and line-count
bookkeeping that rots.

If a reader needs the full story they open the commit, the audit, or the plan. These files
exist to help them find it.

## Templates

In `${CLAUDE_PLUGIN_ROOT}/assets/templates/`:

| Template | Destination |
|-|-|
| `project-CLAUDE.md` | `<project>/CLAUDE.md` |
| `decision-entry.md` | `Docs/Decisions/YYYY-MM-DD.md` |
| `changelog-entry.md` | `<project>/CHANGELOG.md` |
| `Docs-skeleton/` | `<project>/Docs/` — copy wholesale, includes `Audit/README.md` |

`/bootstrap-project` places all of these for you.

**Already have `Doclog/`?** It's the same tree under the older name. Keep it — renaming an
append-only history buys nothing. New projects get `Decisions/`.
