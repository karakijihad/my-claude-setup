---
name: "dependency-auditor"
description: >
  Scan project dependencies for vulnerabilities, license compliance, and upgrade paths.
  Use when: "audit dependencies", "check deps", "scan for vulnerabilities", "license check",
  "upgrade plan", "are my dependencies safe", adding new dependencies, before releases,
  or when SecurityProtocol §6 is relevant.
---

# Dependency Auditor

Scan dependencies for vulnerabilities, license compliance, and safe upgrade paths. Supports JavaScript, Python, Go, Rust, Ruby, Java, PHP, and .NET.

## Quick Start

Invoke the scripts through `scripts/py.sh`, which resolves a working interpreter
(`python3` → `python` → `py -3`). Don't call `python3` directly — on Windows that name
is usually the Microsoft Store alias stub, which exits 9009 without running anything.

```bash
# Full vulnerability scan
scripts/py.sh scripts/dep_scanner.py /path/to/project

# License compliance check
scripts/py.sh scripts/license_checker.py /path/to/project --policy strict

# Upgrade path planning
scripts/py.sh scripts/upgrade_planner.py deps.json --risk-threshold medium

# JSON output for CI
scripts/py.sh scripts/dep_scanner.py /path/to/project --format json --fail-on-high
```

## Scripts

| Script | Purpose |
|-|-|
| `scripts/py.sh` | Interpreter resolver — probes `python3`, `python`, `py -3`; execs the first that runs |
| `scripts/dep_scanner.py` | Vulnerability scanning, CVE matching, transitive dependency analysis |
| `scripts/license_checker.py` | License detection, compatibility matrix, conflict detection |
| `scripts/upgrade_planner.py` | Semver analysis, breaking change prediction, upgrade prioritization |

## Supported Package Files

JavaScript: `package.json`, `package-lock.json`, `yarn.lock`
Python: `requirements.txt`, `pyproject.toml`, `Pipfile.lock`, `poetry.lock`
Go: `go.mod`, `go.sum`
Rust: `Cargo.toml`, `Cargo.lock`
Ruby: `Gemfile`, `Gemfile.lock`
Java: `pom.xml`, `gradle.lockfile`
PHP: `composer.json`, `composer.lock`
.NET: `packages.config`, `project.assets.json`

## When to Run

- **Before adding a new dependency** — scan it first
- **Before releases** — full vulnerability + license audit
- **Weekly** — scheduled vulnerability scan in CI
- **After incidents** — check if vulnerable deps were the vector
- **When SecurityProtocol.md §6 applies** — "audit dependencies before adding, pin versions, run vulnerability scans"

## Upgrade Priority

1. **Security patches** — immediately (high/critical CVEs)
2. **Bug fixes** — high priority
3. **Minor updates** — medium priority, batch monthly
4. **Major updates** — planned, with migration checklist and testing

## CI Integration

```yaml
# GitHub Actions step
- name: Dependency Audit
  run: |
    scripts/py.sh scripts/dep_scanner.py . --format json --fail-on-high
    scripts/py.sh scripts/license_checker.py . --policy strict --format json
```
