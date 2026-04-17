# 5. API & Endpoint Security

> Part of [Security Protocol](./README.md). Read before building or modifying APIs, endpoints, or real-time connections.

## Rate Limiting

- Rate limit all public endpoints. Use IP-based, user-based, or both.
- Auth endpoints (login, register, password reset, MFA verify) get aggressive limits. These are the #1 brute-force target.
- Use exponential backoff or account lockout after repeated failures.
- Return `429 Too Many Requests` with a `Retry-After` header. Don't reveal rate limit internals.

## CORS (Cross-Origin Resource Sharing)

- Whitelist specific allowed origins. Never use `Access-Control-Allow-Origin: *` with credentials.
- Never reflect the `Origin` header blindly as the allowed origin.
- Restrict allowed methods and headers to what's actually needed.
- `Access-Control-Allow-Credentials: true` only if cookies/auth are needed cross-origin.

## CSRF (Cross-Site Request Forgery)

- Anti-CSRF tokens on all state-changing requests (POST, PUT, DELETE, PATCH).
- Use `SameSite=Lax` or `Strict` cookies as a defense-in-depth layer.
- For APIs: require a custom header (e.g., `X-Requested-With`) that browsers won't send in simple cross-origin requests.
- Double-submit cookie pattern as an alternative where token-based CSRF is impractical.

## HTTP Security Headers

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

## Request Size & Payload

- Set maximum request body size at the framework and reverse proxy level. Don't let someone POST a 500MB JSON body.
- Limit JSON depth and array lengths to prevent denial-of-service via deeply nested payloads.
- Set timeouts on all requests — both client-side and server-side.

## Internal Endpoints

- Never expose `/debug`, `/admin`, `/metrics`, `/health` (with sensitive data), `/graphql/playground`, `/__debug__`, `/phpinfo`, `/swagger` without authentication.
- Use network-level restrictions (VPN, IP whitelist) for admin and monitoring endpoints.
- Disable debug mode, verbose error pages, and development tools in production.

## GraphQL-Specific

- Disable introspection in production.
- Implement query depth limiting and query complexity analysis.
- Rate limit by query complexity, not just request count.
- Use persisted/allowlisted queries in production if possible.

## WebSocket-Specific

- Authenticate the WebSocket connection at handshake time.
- Validate and sanitize all messages received over WebSocket — they're user input.
- Implement rate limiting on WebSocket messages.
- Set maximum message size.
