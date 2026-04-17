# [Project Name]

> Copy to `CLAUDE.md` at the project root. Global `~/.claude/CLAUDE.md` handles protocols, tools, and workflow. This file is project-specific context only.

## Project

[1-2 sentence description. What does this project do? Who uses it?]

## Architecture

[High-level architecture, or pointer: "See `Docs/Logs/CODEMAP.md` for the authoritative file map."]

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

This project follows the global `Docs/` convention (see `~/.claude/CLAUDE.md` → Per-Project Docs).

```
Docs/
├── Changelog/YYYY-MM-DD.md
├── Doclog/YYYY-MM-DD.md
├── Sessions/YYYY-MM-DD.md
├── Audit/{agent}/YYYY-MM-DD/audit-{N}.md
├── Plan/
├── Logs/CODEMAP.md
└── Protocols/    # project-specific overrides, rare
```

## Optional Sections

Add if relevant:

- **API Conventions** — REST/GraphQL patterns specific to this project
- **Deployment** — non-obvious deployment steps
- **Third-Party Integrations** — external service quirks
- **Known Tech Debt** — landmines to avoid
