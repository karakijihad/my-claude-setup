# 6. Dependency & Supply Chain Security

> Part of [Security Protocol](./README.md). Read before adding or updating dependencies.

- **Audit dependencies before adding them.** Check maintenance status, download counts, known vulnerabilities, last publish date. Prefer well-maintained, widely-used packages with active security response.
- **Pin dependency versions.** Use lock files (`package-lock.json`, `yarn.lock`, `poetry.lock`, `Cargo.lock`, etc.). Commit lock files. Review what changes on updates.
- **Run vulnerability scans regularly** — `npm audit`, `pip audit`, `snyk`, `trivy`, `cargo audit`, Dependabot, Renovate. Don't ignore the results. Fix or explicitly accept with documented reasoning.
- **Minimize dependencies.** Every dependency is attack surface. If you need one function from a package, consider writing it yourself.
- **Review transitive dependencies.** Your direct dependency might be fine, but its dependency might not be.
- **Verify package integrity.** Use `npm audit signatures`, check checksums, use Sigstore where available.
- **Lock file attacks:** If the lock file changes unexpectedly in a PR, investigate before merging.
- **Typosquatting:** Double-check package names, especially for popular packages. `lodash` vs `1odash` vs `lodahs`.

## Tooling

Run `dependency-auditor` skill for any dependency changes — it handles vulnerability scanning, license compliance, and upgrade paths.

## AI-adjacent supply chain

MCP servers and skills are also supply chain — see [07-AI-Agents.md](./07-AI-Agents.md) sections 7.3 and 7.4.
