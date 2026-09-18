# Audit

Code audits, kept so reviews are persistent, comparable, and easy to hand back into a design
discussion.

```text
Docs/Audit/
├── codex/YYYY-MM-DD/audit-N.md     what the auditor reported
└── claude/YYYY-MM-DD/audit-N.md    the adjudication
```

One folder per agent, one folder per date, numbered within the day.

## What an entry holds

**Findings plus adjudication.** The refutations are the point — a commit shows which findings
were fixed and never which were argued down, or why. That is the only part of an audit git
cannot reconstruct.

Per finding: what was claimed · the verdict (confirmed / refuted / deferred) · the evidence for
that verdict, as `file:line` · what was done about it, or why nothing was.

**An audit is not a decision.** A ruling that changes how the project works goes to
`Docs/Decisions/` as well, in one line.

## Keep it short

Don't paste whole findings blocks, tool output, or the diff. Cite them. An audit file nobody
rereads is the same as no audit file, and length is what stops them being reread.
