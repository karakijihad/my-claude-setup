# [Project Name]

> Copy to `CLAUDE.md` at the project root. The my-claude-setup plugin handles protocols, tools, and workflow. This file is project-specific context only.

## Project

[1-2 sentence description. What does this project do? Who uses it?]

## Architecture

[High-level architecture. For a large repo, generate `Docs/Logs/CODEMAP.md` on demand and point here.]

## Key Files

- `src/` — [description]
- `lib/` — [description]
- `config/` — [description]

## Tech Stack

- Runtime: [e.g., Node 20 / Python 3.12 / Go 1.22]
- Framework: [e.g., Next.js / FastAPI / Gin]
- Database: [e.g., PostgreSQL / MongoDB / SQLite]
- Testing: [e.g., Jest / pytest / go test]

## Commands

```bash
# Install
npm install

# Dev
npm run dev

# Test
npm test

# Build
npm run build

# Lint
npm run lint
```

## Environment

- Copy `.env.example` to `.env`
- Required: `DATABASE_URL`, `API_KEY`
- Local services: `docker compose up -d`

## Gotchas

- [e.g., "ORM doesn't support X — use raw queries for Y"]
- [e.g., "Tests must run sequentially — no parallel runner"]
- [e.g., "Auth middleware reads from X header, not Authorization"]

## Docs Layout

This project follows the global `Docs/` convention (see the `project-docs` skill).

```
Docs/
├── Decisions/YYYY-MM-DD.md            why, and what was rejected
├── Audit/{agent}/YYYY-MM-DD/audit-{N}.md
└── Plan/                              in-flight work only
CHANGELOG.md                           repo root, committed
```

Only what git cannot reconstruct. Created on demand, not scaffolded: `Docs/Protocols/` for a
project override, `Docs/Logs/CODEMAP.md` for a structural map.

## Optional Sections

Add if relevant:

- **API Conventions** — REST/GraphQL patterns specific to this project
- **Deployment** — non-obvious deployment steps
- **Third-Party Integrations** — external service quirks
- **Known Tech Debt** — landmines to avoid
