# 8. Common Attack Vectors — Checklist

> Part of [Security Protocol](./README.md). Pre-commit reference for code that handles user input, auth, data access, or external communication.

Check relevant items before committing code that handles user input, auth, data access, or external communication.

| Attack | What to Check |
|--------|--------------|
| **SQL Injection** | All queries parameterized. Zero string concatenation in queries. |
| **XSS (Cross-Site Scripting)** | All output encoded for context. No raw user content in HTML/JS/attributes. CSP blocks inline scripts. |
| **CSRF** | Anti-CSRF tokens on all state-changing requests. SameSite cookies set. |
| **SSRF (Server-Side Request Forgery)** | User-provided URLs validated and whitelisted before server-side fetch. Internal network ranges blocked. |
| **Path Traversal** | No user input in file paths without sanitization. Canonical path verified within allowed directory. |
| **IDOR / Auth Bypass** | Every resource access verifies the requesting user has permission. Role checks on every endpoint. Tested with different/no auth tokens. |
| **Mass Assignment** | Explicit field whitelists on all create/update operations. Request bodies never passed blindly to models. |
| **Secrets Exposure** | No API keys, tokens, or passwords in code, logs, error messages, or git history. |
| **Prompt Injection** | External content flowing into agent tools treated as untrusted. Destructive actions confirmed out-of-band. See [07-AI-Agents.md](./07-AI-Agents.md) §7.1. |
| **Skill / MCP Supply Chain** | Third-party skills and MCP servers audited before install. Pinned versions where possible. See [07-AI-Agents.md](./07-AI-Agents.md) §7.3-7.4. |

For each row that applies, read the relevant subfile for detailed guidance.
