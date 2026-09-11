# 6. Dependency & Supply Chain Security

> Part of [Security Protocol](../SKILL.md). Read before adding or updating dependencies.

- **Audit dependencies before adding them.** Check maintenance status, download counts, known vulnerabilities, last publish date. Prefer well-maintained, widely-used packages with active security response.
- **Pin dependency versions.** Use lock files (`package-lock.json`, `yarn.lock`, `poetry.lock`, `Cargo.lock`, etc.). Commit lock files. Review what changes on updates.
- **Run vulnerability scans regularly.** Don't ignore the results. Fix or explicitly accept with documented reasoning.
- **Minimize dependencies.** Every dependency is attack surface. If you need one function from a package, consider writing it yourself.
- **Review transitive dependencies.** Your direct dependency might be fine, but its dependency might not be.
- **Verify package integrity.** Use `npm audit signatures`, check checksums, use Sigstore where available.
- **Lock file attacks:** If the lock file changes unexpectedly in a PR, investigate before merging.
- **Typosquatting:** Double-check package names, especially for popular packages. `lodash` vs `1odash` vs `lodahs`.

## Running the audit

Detect ecosystems from the manifests present (`package.json`, `requirements.txt`/`pyproject.toml`,
`go.mod`, `Cargo.toml`, `Gemfile`, `composer.json`), run the native scanner for each, and
synthesize one report. Native tools, not bundled snapshots: they query current vulnerability
databases.

| Ecosystem   | Vulnerabilities                                    | Licenses                                | Outdated                            |
| ----------- | -------------------------------------------------- | --------------------------------------- | ----------------------------------- |
| JavaScript  | `npm audit --json` (or `pnpm`/`yarn audit`)        | `npx license-checker --json --summary`  | `npm outdated --json`               |
| Python      | `pip-audit --format json`                          | `pip-licenses --format=json`            | `pip list --outdated --format=json` |
| Go          | `govulncheck ./...`                                | `go-licenses report ./...`              | `go list -u -m all`                 |
| Rust        | `cargo audit --json`                               | `cargo license --json`                  | `cargo outdated`                    |
| Ruby        | `bundle audit check --update`                      | —                                       | `bundle outdated`                   |
| Any / mixed | `osv-scanner --format json -r .`                   | —                                       | —                                   |

**A missing tool is a gap, not a pass.** Never report "no vulnerabilities" unless a scanner
actually ran and returned clean — say the tool is missing and offer to install it. Include the
tool name and database version in the report. For each finding: package, installed version,
fixed version, severity, and the one-line upgrade command.

**Licenses:** flag against the project's own — strong copyleft (GPL/AGPL) in a permissive or
proprietary project, unknown/unlicensed packages, and license changes on upgrade. LGPL is
dynamic-linking-friendly; don't treat it like GPL.

**Upgrade order:** security patches immediately; patch bumps high; minor batched; major planned
against the package's migration guide, with changelogs read before recommending.

**When:** before adding a dependency (scan it *first*), before a release, and after any incident
where a dependency could have been the vector.

## AI-adjacent supply chain

MCP servers and skills are also supply chain — see [07-AI-Agents.md](./07-AI-Agents.md) sections 7.3 and 7.4.
