# 9. Security Review Gate

> Part of [Security Protocol](./README.md). Read before every security-relevant commit.

**Triggers:** Any commit that touches auth, endpoints, user input handling, file operations, data access patterns, cryptography, adds/updates dependencies, or changes agent / MCP / skill configuration.

## Process

1. Run the attack vector checklist in [08-Attack-Vectors.md](./08-Attack-Vectors.md) against the diff — check only rows relevant to this change. For AI workflow changes, run the gate in [07-AI-Agents.md](./07-AI-Agents.md) §7.11.
2. Get a security review — `feature-dev:code-reviewer` agent with an explicit security brief, a manual review pass, or pair review. The method is flexible. The review is not.
3. The review must explicitly check: injection, auth bypass, IDOR, XSS, SSRF, secrets exposure, privilege escalation, mass assignment, CSRF, and (for AI workflows) prompt injection and supply chain.
4. If the review doesn't check these, it's not a security review.

## Quick security audit (run before commit)

```
Grep for: TODO security, FIXME security, password, secret, token, api_key, hardcoded
Check: .env in .gitignore, no secrets in committed files
Run: dependency-auditor skill for any dependency changes
Run: skill-security-auditor on any newly installed skill or MCP server
Verify: all new endpoints have auth middleware
```
