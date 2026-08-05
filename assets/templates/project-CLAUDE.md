# [Project Name]

> Copy to `CLAUDE.md` at the project root. The my-claude-setup plugin handles protocols, tools, and workflow. This file is project-specific context only.

## Project

[1-2 sentence description. What does this project do? Who uses it?]

## Architecture

[High-level architecture. Roles and data flows, not a file listing — a file listing goes stale and then misleads.]

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

Only what git cannot reconstruct. There is no fourth folder — anything this project must do
differently from a protocol belongs in **this file**, which is loaded every session.

`Docs/` is gitignored (`/Docs/`), whole tree, subfolders included: it holds working evidence,
some of it private. To version it instead, delete the ignore line and replace this paragraph
with the section below — it is what stops a later session helpfully re-adding the line.

```md
## Docs policy

`Docs/` is versioned in this repo on purpose. Do not add `/Docs/` to `.gitignore`.
```

## Optional Sections

Add if relevant:

- **API Conventions** — REST/GraphQL patterns specific to this project
- **Deployment** — non-obvious deployment steps
- **Third-Party Integrations** — external service quirks
- **Known Tech Debt** — landmines to avoid
