# <Project> code map

> Destination: `Docs/CODEMAP.md`. Only for a repo too large to hold in one head.
> **Budget: 300 lines.** This header is the single source of truth for that number.
> **Roles, not histories.** What each unit is *for*. How it got that way is in the commits;
> how it works is in the source. A map that explains mechanism is a second copy of the code,
> and it is the copy that goes stale.
> **Never here:** phase notes · a changelog · anything that would change under a refactor.

**Regenerate when:** <the trigger — e.g. a top-level package is added or renamed>. A budget
keeps a map short; only a trigger keeps it true.

Last regenerated: YYYY-MM-DD @ `a1b2c3d`

## Layout

```
src/
├── api/     HTTP surface. Owns request shape and status codes, nothing else.
├── core/    The domain. No I/O, no framework imports — this is what keeps the rest testable.
├── store/   Persistence. The only place that knows the schema.
└── cli/     Entry points. Thin: parse argv, call core, format output.
```

## Boundaries

Only the ones a newcomer would otherwise violate.

- `core/` must not import `api/` or `store/`. Enforced by `tests/test_layering.py`.
- Everything reaching the network goes through `store/http.py`, so retries have one home.
