# Plan

Stage checklists for in-flight work — typically multi-step implementations broken into stages with verification gates.

One file per plan:

```
Plan/
├── 2026-04-17-feature-auth.md
└── 2026-04-12-refactor-payments.md
```

Each plan should include: goal, stages, verification checks per stage, and a kill-switch (what aborts the plan). Completed plans get moved to `Plan/archive/` or deleted.

Every plan file carries this line under its header, because the code moves while the plan sits still:

```markdown
> Before starting any phase, scout it against the codebase first — brief and skip condition in `my-claude-setup:planning-protocol` §4. The plan is older than the code.
```

See `superpowers:writing-plans` skill for the preferred structure.
