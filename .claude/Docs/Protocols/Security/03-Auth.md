# 3. Authentication & Authorization

> Part of [Security Protocol](./README.md). Read before writing or modifying auth, login, permissions, or token handling.

## Authentication (Who are you?)

- **Hash passwords with bcrypt, scrypt, or argon2id.** Never MD5, SHA-1, or SHA-256 alone. Never store plaintext. Never log passwords — not even hashed ones.
- **Salt every hash.** Bcrypt/argon2 do this automatically. If using a manual scheme, generate a unique cryptographically random salt per user.
- **Enforce password policies** at registration and change: minimum length (12+), check against known breached password lists (haveibeenpwned API), no maximum length under 128 characters.
- **Multi-factor authentication (MFA):** Implement or support it wherever user accounts exist. TOTP or WebAuthn preferred over SMS.
- **Account lockout / throttling:** Lock or delay after repeated failed attempts. Use exponential backoff. Notify the user of failed attempts.
- **Password reset flows:** Use time-limited, single-use tokens. Send to verified email only. Never reveal whether an email exists in the system ("If an account exists, we've sent a reset link").
- **OAuth / third-party auth:** Validate tokens server-side. Verify `iss`, `aud`, `exp` claims. Don't trust the client to validate JWTs. Use the `state` parameter to prevent CSRF on OAuth flows.

## Authorization (What can you do?)

- **Check authorization on the server for every request.** Not just in the UI. Not just on the first request. Every single one. A hidden button is not access control.
- **IDOR (Insecure Direct Object Reference):** Never trust user-supplied IDs to access resources. Always verify the requesting user owns or has permission to access the resource. `/api/invoices/123` must confirm the logged-in user owns invoice 123. This applies to GETs, PUTs, DELETEs — all verbs.
- **Principle of least privilege.** Every user, service, token, and database connection gets the minimum access needed. No shared admin accounts. No wildcard permissions. No `SELECT *` from tables with sensitive columns unless every column is needed.
- **Role-based or attribute-based access control:** Enforce at the middleware/decorator level, not scattered through business logic. Centralize permission checks.
- **Privilege escalation testing:** Verify both vertical (user → admin) and horizontal (user A → user B's data) escalation paths. Test by replaying requests with different/no auth tokens.

## Session Management

- Use `Secure`, `HttpOnly`, `SameSite=Lax` (or `Strict`) cookies for session identifiers.
- Generate cryptographically random session IDs (minimum 128 bits of entropy).
- Set reasonable session expiry. Absolute timeout (e.g., 24h) and idle timeout (e.g., 30min).
- Invalidate sessions on logout **server-side** — don't just clear the client cookie.
- Rotate session IDs after any privilege change (login, role change, password change).
- Store sessions server-side (database, Redis). Never store session state solely in a client-side cookie or JWT without server-side revocation capability.

## JWT-Specific

- Always verify signature server-side. Never trust `alg: none`.
- Validate `iss`, `aud`, `exp`, `nbf` claims.
- Keep JWTs short-lived. Use refresh tokens for long sessions.
- Store JWTs in `HttpOnly` cookies, not localStorage (XSS can steal localStorage).
- Have a revocation strategy (token blacklist, short expiry + refresh rotation, or session store).

## API Keys and Tokens

- Never in client-side code, URLs, query strings, logs, git, or error messages.
- Always in environment variables or a secrets manager.
- Scope keys to minimum required permissions.
- Rotate regularly. Support key rotation without downtime.
