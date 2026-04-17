# 10. Verification Checklist — Security Gate

> Part of [Security Protocol](./README.md). Final checklist before merging security-relevant changes.

Required if the change touches auth, endpoints, user input, file operations, dependencies, or agent / MCP / skill configuration.

## Application security

- [ ] All inputs validated and sanitized server-side
- [ ] Database queries parameterized (zero string concatenation)
- [ ] Output encoded for its rendering context (HTML, JS, URL, SQL)
- [ ] Auth checked on every protected endpoint (not just UI)
- [ ] No secrets, tokens, or PII in code, logs, or error messages
- [ ] `.env` / config files in `.gitignore`
- [ ] IDOR check: users can only access their own resources
- [ ] Rate limiting on public and auth endpoints
- [ ] CORS, CSRF, and security headers configured
- [ ] Dependencies audited and vulnerability scan clean
- [ ] File uploads validated by content (not extension/header)
- [ ] No internal endpoints exposed without auth
- [ ] Error messages reveal nothing about internals

## AI / agent workflow

- [ ] Tool permissions scoped to least privilege in `settings.json`
- [ ] MCP servers and skills audited before install
- [ ] No production secrets in agent context
- [ ] External content treated as untrusted input (prompt-injection risk)
- [ ] Destructive commands gated on explicit confirmation
- [ ] Subagent / agent-team permissions reviewed before dispatch
- [ ] Transcripts reviewed before external sharing
- [ ] Generated / suggested code cross-checked against official docs

## Closeout

- [ ] Security review completed (see [09-Review-Gate.md](./09-Review-Gate.md))
- [ ] Findings recorded in session note under "Security Review"
