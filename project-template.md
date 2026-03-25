# Project Template

> Copy this into a new project as `CLAUDE.md` and fill in each section.
> The global `~/.claude/CLAUDE.md` handles protocols, tools, and workflow.
> This file only needs project-specific context.

---

```markdown
# [Project Name]

## Project

[1-2 sentence description. What does this project do? Who uses it?]

## Architecture

[High-level architecture. Or pointer: "See Docs/CodeMap.md for the authoritative file map."]

## Key Files

[Top 5-6 files or directories that matter most]

- `src/` — [description]
- `lib/` — [description]
- `config/` — [description]

## Tech Stack

[Languages, frameworks, databases, key dependencies]

- Runtime: Node 20 / Python 3.12 / Go 1.22
- Framework: Next.js / FastAPI / Gin
- Database: PostgreSQL / MongoDB / SQLite
- Testing: Jest / pytest / go test

## Commands

[Project-specific commands Claude should know]

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Run tests
npm test

# Build for production
npm run build

# Lint
npm run lint
```

## Environment

[Required env vars and setup steps]

- Copy `.env.example` to `.env`
- Required vars: `DATABASE_URL`, `API_KEY`
- Docker: `docker compose up -d` for local services

## Gotchas

[Project-specific quirks, footguns, and things Claude should watch out for]

- [e.g., "The ORM doesn't support X — use raw queries for Y"]
- [e.g., "Tests must run sequentially — no parallel test runner"]
- [e.g., "The auth middleware reads from X header, not Authorization"]
```

---

## Optional Sections

Add these if the project needs them:

**## API Conventions** — if the project has specific REST/GraphQL patterns.
**## Deployment** — if there are non-obvious deployment steps.
**## Third-Party Integrations** — if the project talks to external services with quirks.
**## Known Tech Debt** — if there are landmines Claude should be aware of.
