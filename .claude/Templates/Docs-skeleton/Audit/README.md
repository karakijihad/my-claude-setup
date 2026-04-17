# Audit Folder Usage

## Purpose

This folder stores code audits from different agents.

The goal is to make reviews:

- persistent
- comparable
- easy to hand off
- easy to present back into the main design discussion

---

## Structure

```text
Docs/Audit/
├── README.md
├── codex/
│   └── YYYY-MM-DD/
│       ├── audit-1.md
│       ├── audit-2.md
│       └── supporting-note.md
└── claude/
    └── YYYY-MM-DD/
        └── audit-1.md
```

Use one dated folder per review day. Within that folder:

- primary audit passes use `audit-{N}.md`
- supporting notes may use descriptive names

---

## Naming Rule

Use:

```text
Docs/Audit/<agent>/YYYY-MM-DD/audit-{N}.md
```

Example:

```text
Docs/Audit/codex/2026-04-03/audit-1.md
Docs/Audit/codex/2026-04-03/audit-2.md
```

This keeps review history chronological, grouped by day, and easy to diff.

---

## What Each Audit Should Contain

Recommended structure:

```markdown
# [Agent] Audit — YYYY-MM-DD

## Scope
## Executive Summary
## Findings
## Verification Notes
## Most Important Corrections
## Overall Assessment
```

The audit should focus on:

- defects
- architectural mismatches
- pipeline/logical issues
- missing wiring
- verification gaps
- priority corrections

Avoid using the audit as a brainstorming note or future roadmap unless clearly marked.

---

## How To Use With Codex

Ask Codex to:

- inspect the live implementation
- compare docs against code
- identify wiring gaps and defects
- write findings to `Docs/Audit/codex/YYYY-MM-DD/audit-{N}.md`

Best use cases for Codex:

- implementation review
- runtime path scrutiny
- tool/pipeline defects
- packaging/config problems
- verification and test gaps

---

## How To Use With Claude

Ask Claude to:

- read the latest Codex audit
- cross-check findings against the architecture intent
- challenge weak conclusions
- write its own review to `Docs/Audit/claude/YYYY-MM-DD/audit-{N}.md`

Best use cases for Claude:

- architecture-level review
- plan/design corrections
- prioritization
- reconciling design intent with implementation reality

---

## Recommended Review Workflow

### Option A — Codex first

1. Codex reviews implementation and writes audit
2. Claude reads the audit and challenges/confirms it
3. Final decisions go into `Docs/Doclog/YYYY-MM-DD.md`
4. Work updates go into `Docs/Sessions/YYYY-MM-DD.md`

### Option B — Claude first

1. Claude reviews architecture/design intent
2. Codex verifies against live code
3. Differences become explicit action items

---

## Important Rule

An audit is not a decision by itself.

Use audits as:

- evidence
- review input
- handoff material

Final accepted architecture or implementation decisions should be recorded in:

- `Docs/Doclog/YYYY-MM-DD.md`
- `Docs/Sessions/YYYY-MM-DD.md`
- stage checklists under `Docs/Plan/`

---

## Practical Guidance

- Keep findings concrete.
- Prefer evidence over opinion.
- Separate confirmed defects from unverified concerns.
- Mark severity when useful.
- Add a new `audit-{N}.md` inside the current date folder instead of rewriting old audits.
- Keep supporting design notes beside the same day's audits when they are directly related.
