# Security Protocol

> Referenced by `~/.claude/CLAUDE.md`. Read this before writing any code that touches auth, endpoints, user input, file operations, data storage, or dependencies.
> Applies to all project types — web apps, APIs, CLIs, mobile, serverless, microservices, static sites with backends.
> **Skip the checklist** for pure UI/styling changes, config-only changes, or documentation. Apply judgment for everything else.

**Core principle: every input is hostile, every endpoint is a target, every default is wrong until proven safe.**

---

## 1. Threat Assessment — Do This First

Before writing code for any feature, endpoint, or phase — answer these:

- What does this feature expose? (endpoints, file access, user input, auth, data, third-party integrations)
- Who can reach it? (anonymous users, authenticated users, admins, internal services, automated bots)
- What's the worst thing an attacker could do with it?
- What's the blast radius if this component is compromised?
- What trust boundaries does data cross? (client → server, service → service, server → database, server → third-party)

If you can't answer these, stop and figure it out before coding. Assumptions here become vulnerabilities later.

---

## 2. Input Validation — Trust Nothing

Every piece of data that enters the system is untrusted until validated. This includes data from your own client, your own database (if another path could have written to it), and other internal services.

### Rules

- **Validate and sanitize every input.** Query params, request bodies, headers, cookies, file uploads, URL paths, WebSocket messages, environment variables read at runtime — all of it.
- **Server-side, always.** Client-side validation is UX, not security. It can be bypassed in seconds.
- **Whitelist over blacklist.** Define what's allowed, reject everything else. Blacklists always miss something.
- **Enforce type, length, range, and format at the boundary.** An email field should reject a 10MB string before it hits any logic. An age field should reject negative numbers and strings.
- **Fail closed.** If validation is ambiguous, reject the input. Don't try to "fix" or "clean" malformed input and pass it through.

### Database Queries

- **Parameterize all queries. No exceptions.** No string concatenation. No template literals. No f-strings. Use prepared statements or your ORM's parameterized methods.
- This applies to SQL, NoSQL (MongoDB query injection is real), GraphQL, LDAP, and any query language.
- ORMs are not magic — raw queries through an ORM still need parameterization.

### Output Encoding

- **Encode output for its rendering context.** The same data needs different encoding depending on where it appears:
  - HTML body → HTML-encode (`<` → `&lt;`)
  - HTML attributes → attribute-encode (quote and encode)
  - JavaScript → JS-encode (or use JSON.stringify, never template into script tags)
  - URLs → URL-encode (`encodeURIComponent`)
  - SQL → parameterize (never encode manually)
  - CSS → CSS-encode or avoid dynamic CSS values entirely
  - Markdown, CSV, XML, shell commands — each has its own escaping rules
- **Never inject raw user content into any output context.**

### File Uploads

- Validate MIME type by content inspection (magic bytes), not just the extension or `Content-Type` header.
- Restrict to explicitly allowed types. Reject everything else.
- Limit file size at the reverse proxy / framework level, not just application code.
- Never serve uploads from the same origin as the application. Use a separate domain or CDN with `Content-Disposition: attachment`.
- Never let user input determine the storage path or filename. Generate random filenames. Resolve canonical paths and verify they're within the allowed directory.
- Strip EXIF and metadata from images before storage if privacy matters.
- Scan for malware if the use case warrants it.

---

## 3. Authentication & Authorization

### Authentication (Who are you?)

- **Hash passwords with bcrypt, scrypt, or argon2id.** Never MD5, SHA-1, or SHA-256 alone. Never store plaintext. Never log passwords — not even hashed ones.
- **Salt every hash.** Bcrypt/argon2 do this automatically. If using a manual scheme, generate a unique cryptographically random salt per user.
- **Enforce password policies** at registration and change: minimum length (12+), check against known breached password lists (haveibeenpwned API), no maximum length under 128 characters.
- **Multi-factor authentication (MFA):** Implement or support it wherever user accounts exist. TOTP or WebAuthn preferred over SMS.
- **Account lockout / throttling:** Lock or delay after repeated failed attempts. Use exponential backoff. Notify the user of failed attempts.
- **Password reset flows:** Use time-limited, single-use tokens. Send to verified email only. Never reveal whether an email exists in the system ("If an account exists, we've sent a reset link").
- **OAuth / third-party auth:** Validate tokens server-side. Verify `iss`, `aud`, `exp` claims. Don't trust the client to validate JWTs. Use the `state` parameter to prevent CSRF on OAuth flows.

### Authorization (What can you do?)

- **Check authorization on the server for every request.** Not just in the UI. Not just on the first request. Every single one. A hidden button is not access control.
- **IDOR (Insecure Direct Object Reference):** Never trust user-supplied IDs to access resources. Always verify the requesting user owns or has permission to access the resource. `/api/invoices/123` must confirm the logged-in user owns invoice 123. This applies to GETs, PUTs, DELETEs — all verbs.
- **Principle of least privilege.** Every user, service, token, and database connection gets the minimum access needed. No shared admin accounts. No wildcard permissions. No `SELECT *` from tables with sensitive columns unless every column is needed.
- **Role-based or attribute-based access control:** Enforce at the middleware/decorator level, not scattered through business logic. Centralize permission checks.
- **Privilege escalation testing:** Verify both vertical (user → admin) and horizontal (user A → user B's data) escalation paths. Test by replaying requests with different/no auth tokens.

### Session Management

- Use `Secure`, `HttpOnly`, `SameSite=Lax` (or `Strict`) cookies for session identifiers.
- Generate cryptographically random session IDs (minimum 128 bits of entropy).
- Set reasonable session expiry. Absolute timeout (e.g., 24h) and idle timeout (e.g., 30min).
- Invalidate sessions on logout **server-side** — don't just clear the client cookie.
- Rotate session IDs after any privilege change (login, role change, password change).
- Store sessions server-side (database, Redis). Never store session state solely in a client-side cookie or JWT without server-side revocation capability.

### JWT-Specific

- Always verify signature server-side. Never trust `alg: none`.
- Validate `iss`, `aud`, `exp`, `nbf` claims.
- Keep JWTs short-lived. Use refresh tokens for long sessions.
- Store JWTs in `HttpOnly` cookies, not localStorage (XSS can steal localStorage).
- Have a revocation strategy (token blacklist, short expiry + refresh rotation, or session store).

### API Keys and Tokens

- Never in client-side code, URLs, query strings, logs, git, or error messages.
- Always in environment variables or a secrets manager.
- Scope keys to minimum required permissions.
- Rotate regularly. Support key rotation without downtime.

---

## 4. Data Protection

### Secrets Management

- **Secrets (API keys, tokens, passwords, connection strings, encryption keys):** Never hardcoded. Never committed. Never logged. Never in error messages. Never in client bundles.
- Use `.env` files (gitignored) locally. Use a secrets manager (Vault, AWS Secrets Manager, GCP Secret Manager, etc.) in production.
- **If a secret was ever committed, rotate it immediately.** Git history is permanent. Rewriting history is unreliable. Assume it's compromised.
- Pre-commit hooks: Use tools like `git-secrets`, `trufflehog`, or `gitleaks` to catch secrets before they're committed.

### Data in Transit

- HTTPS everywhere. No exceptions. No mixed content.
- Set `Strict-Transport-Security` (HSTS) header with `max-age` of at least one year and `includeSubDomains`.
- Use TLS 1.2+ only. Disable older protocols.
- Certificate pinning for mobile apps or high-security APIs where appropriate.
- Internal service-to-service traffic should also be encrypted (mTLS or TLS).

### Data at Rest

- Encrypt PII and sensitive fields at the application or database level, not just disk encryption.
- Know your data classification. What's PII? What's sensitive? What's public?
- Don't store what you don't need. Minimize data collection.
- Have a retention and deletion policy. Actually enforce it. GDPR, CCPA, and similar regulations require this.
- Encryption keys: store separately from the data they protect. Rotate periodically.

### Logging

- **Never log:** passwords (even hashed), tokens, session IDs, credit card numbers, SSNs, full request/response bodies with sensitive fields, PII beyond what's necessary for debugging.
- Scrub or mask sensitive fields before logging. Log the structure, not the content.
- Centralize logs. Set retention policies. Restrict access to log systems.
- Structured logging (JSON) over unstructured text — makes it easier to filter and redact.

### Error Handling

- **Never expose to the client:** stack traces, database errors, internal file paths, SQL queries, system architecture details, dependency versions, or debug information.
- Log detailed errors server-side with correlation IDs.
- Return generic messages to users: "Something went wrong. Reference: abc-123."
- Different error detail levels per environment: verbose in development, minimal in production.

### Configuration Files

- `.env`, `.env.local`, `.env.production`, config files with secrets: **always in `.gitignore`**. Verify before every commit.
- Provide `.env.example` with dummy values for onboarding. Never real credentials.
- Database connection strings, API keys, signing secrets — all go through environment variables, never config files checked into source control.

---

## 5. API & Endpoint Security

### Rate Limiting

- Rate limit all public endpoints. Use IP-based, user-based, or both.
- Auth endpoints (login, register, password reset, MFA verify) get aggressive limits. These are the #1 brute-force target.
- Use exponential backoff or account lockout after repeated failures.
- Return `429 Too Many Requests` with a `Retry-After` header. Don't reveal rate limit internals.

### CORS (Cross-Origin Resource Sharing)

- Whitelist specific allowed origins. Never use `Access-Control-Allow-Origin: *` with credentials.
- Never reflect the `Origin` header blindly as the allowed origin.
- Restrict allowed methods and headers to what's actually needed.
- `Access-Control-Allow-Credentials: true` only if cookies/auth are needed cross-origin.

### CSRF (Cross-Site Request Forgery)

- Anti-CSRF tokens on all state-changing requests (POST, PUT, DELETE, PATCH).
- Use `SameSite=Lax` or `Strict` cookies as a defense-in-depth layer.
- For APIs: require a custom header (e.g., `X-Requested-With`) that browsers won't send in simple cross-origin requests.
- Double-submit cookie pattern as an alternative where token-based CSRF is impractical.

### HTTP Security Headers

Set these on every response:

| Header | Value | Why |
|--------|-------|-----|
| `Content-Security-Policy` | Restrict `script-src`, `style-src`, `img-src`, etc. Block `unsafe-inline` and `unsafe-eval` | XSS mitigation |
| `X-Content-Type-Options` | `nosniff` | Prevent MIME-type sniffing |
| `X-Frame-Options` | `DENY` or `SAMEORIGIN` | Clickjacking prevention |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` | Force HTTPS |
| `Referrer-Policy` | `strict-origin-when-cross-origin` or `no-referrer` | Limit referrer leakage |
| `Permissions-Policy` | Disable unused browser features (`camera=(), microphone=()`, etc.) | Reduce attack surface |
| Remove `X-Powered-By` | — | Don't advertise your stack |
| Remove `Server` | — | Don't advertise your server |

### Request Size & Payload

- Set maximum request body size at the framework and reverse proxy level. Don't let someone POST a 500MB JSON body.
- Limit JSON depth and array lengths to prevent denial-of-service via deeply nested payloads.
- Set timeouts on all requests — both client-side and server-side.

### Internal Endpoints

- Never expose `/debug`, `/admin`, `/metrics`, `/health` (with sensitive data), `/graphql/playground`, `/__debug__`, `/phpinfo`, `/swagger` without authentication.
- Use network-level restrictions (VPN, IP whitelist) for admin and monitoring endpoints.
- Disable debug mode, verbose error pages, and development tools in production.

### GraphQL-Specific

- Disable introspection in production.
- Implement query depth limiting and query complexity analysis.
- Rate limit by query complexity, not just request count.
- Use persisted/allowlisted queries in production if possible.

### WebSocket-Specific

- Authenticate the WebSocket connection at handshake time.
- Validate and sanitize all messages received over WebSocket — they're user input.
- Implement rate limiting on WebSocket messages.
- Set maximum message size.

---

## 6. Dependency & Supply Chain Security

- **Audit dependencies before adding them.** Check maintenance status, download counts, known vulnerabilities, last publish date. Prefer well-maintained, widely-used packages with active security response.
- **Pin dependency versions.** Use lock files (`package-lock.json`, `yarn.lock`, `poetry.lock`, `Cargo.lock`, etc.). Commit lock files. Review what changes on updates.
- **Run vulnerability scans regularly** — `npm audit`, `pip audit`, `snyk`, `trivy`, `cargo audit`, Dependabot, Renovate. Don't ignore the results. Fix or explicitly accept with documented reasoning.
- **Minimize dependencies.** Every dependency is attack surface. If you need one function from a package, consider writing it yourself.
- **Review transitive dependencies.** Your direct dependency might be fine, but its dependency might not be.
- **Verify package integrity.** Use `npm audit signatures`, check checksums, use Sigstore where available.
- **Lock file attacks:** If the lock file changes unexpectedly in a PR, investigate before merging.
- **Typosquatting:** Double-check package names, especially for popular packages. `lodash` vs `1odash` vs `lodahs`.

---

## 7. Common Attack Vectors — Checklist

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

---

## 8. Security Review Gate

**Triggers:** Any commit that touches auth, endpoints, user input handling, file operations, data access patterns, cryptography, or adds/updates dependencies.

**Process:**

1. Run the attack vector checklist (Section 7) against the diff — check only rows relevant to this change.
2. Get a security review — `feature-dev:code-reviewer` agent with an explicit security brief, a manual review pass, or pair review. The method is flexible. The review is not.
3. The review must explicitly check: injection, auth bypass, IDOR, XSS, SSRF, secrets exposure, privilege escalation, mass assignment, and CSRF.
4. If the review doesn't check these, it's not a security review.

**Quick security audit (run before commit):**

```
Grep for: TODO security, FIXME security, password, secret, token, api_key, hardcoded
Check: .env in .gitignore, no secrets in committed files
Run: dependency-auditor skill for any dependency changes
Verify: all new endpoints have auth middleware
```

---

## 9. Verification Checklist — Security Gate

Required if the change touches auth, endpoints, user input, file operations, or dependencies:

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
- [ ] Security review completed before commit
- [ ] File uploads validated by content (not extension/header)
- [ ] No internal endpoints exposed without auth
- [ ] Error messages reveal nothing about internals

---

*This document is the single source of truth for security. If `~/.claude/CLAUDE.md` contradicts it, this file wins.*
