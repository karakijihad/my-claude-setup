---
name: "dependency-auditor"
description: >
  Scan project dependencies for vulnerabilities, license compliance, and upgrade paths
  by driving each ecosystem's native audit tooling. Use when: "audit dependencies",
  "check deps", "scan for vulnerabilities", "license check", "upgrade plan",
  "are my dependencies safe", adding new dependencies, before releases,
  or when Security Protocol 06-Dependencies.md is relevant.
---

# Dependency Auditor

Audit dependencies using the ecosystem's **native tools** — real, current vulnerability databases, not bundled snapshots. Detect the ecosystem from the manifest files present, run the matching commands, and synthesize one report.

## Workflow

1. **Detect ecosystems** — look for manifests: `package.json`, `requirements.txt`/`pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`, `composer.json`.
2. **Run the native scanners** (below) for each ecosystem found.
3. **Synthesize** — one report: vulnerabilities by severity, license flags, upgrade plan.
4. **If a tool is missing**, say so explicitly and offer to install it — never silently skip a scan and report "clean."

## Vulnerability Scanning

| Ecosystem   | Command                                            | Notes                                                 |
| ----------- | -------------------------------------------------- | ----------------------------------------------------- |
| JavaScript  | `npm audit --json` (or `pnpm audit`, `yarn audit`) | Built in — no install needed                          |
| Python      | `pip-audit --format json`                          | `pip install pip-audit` if missing                    |
| Go          | `govulncheck ./...`                                | `go install golang.org/x/vuln/cmd/govulncheck@latest` |
| Rust        | `cargo audit --json`                               | `cargo install cargo-audit` if missing                |
| Ruby        | `bundle audit check --update`                      | `gem install bundler-audit` if missing                |
| Any / mixed | `osv-scanner --format json -r .`                   | Cross-ecosystem fallback (OSV database)               |

## License Compliance

| Ecosystem  | Command                                                   |
| ---------- | --------------------------------------------------------- |
| JavaScript | `npx license-checker --json --summary`                    |
| Python     | `pip-licenses --format=json` (`pip install pip-licenses`) |
| Rust       | `cargo license --json` (`cargo install cargo-license`)    |
| Go         | `go-licenses report ./...`                                |

Flag against the project's license: strong copyleft (GPL/AGPL) in permissive or proprietary projects, unknown/unlicensed packages, and license changes on upgrade. LGPL is dynamic-linking-friendly — don't treat it like GPL.

## Upgrade Planning

| Ecosystem  | Command                             |
| ---------- | ----------------------------------- |
| JavaScript | `npm outdated --json`               |
| Python     | `pip list --outdated --format=json` |
| Rust       | `cargo outdated` (if installed)     |
| Go         | `go list -u -m all`                 |

Prioritize:

1. **Security patches** — immediately (high/critical CVEs from the scan above)
2. **Bug fixes** (patch bumps) — high priority
3. **Minor updates** — medium priority, batch monthly
4. **Major updates** — planned, with the package's migration guide and testing; check changelogs for breaking changes before recommending

## When to Run

Before adding a dependency (scan it *first*), before a release, after an incident where a
dependency could have been the vector, and on whatever schedule CI enforces. The policy behind
this lives in `security-protocol` §06 — don't restate it here.

## Reporting Rules

- Never report "no vulnerabilities" unless a scanner actually ran and returned clean. A missing tool is a gap, not a pass.
- Include the tool name and database date/version in the report so results are traceable.
- For each finding: package, installed version, fixed version, severity, and the one-line upgrade command.
