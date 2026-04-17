# 2. Input Validation — Trust Nothing

> Part of [Security Protocol](./README.md). Read before handling any user-facing input, database query, or file operation.

Every piece of data that enters the system is untrusted until validated. This includes data from your own client, your own database (if another path could have written to it), and other internal services.

## Rules

- **Validate and sanitize every input.** Query params, request bodies, headers, cookies, file uploads, URL paths, WebSocket messages, environment variables read at runtime — all of it.
- **Server-side, always.** Client-side validation is UX, not security. It can be bypassed in seconds.
- **Whitelist over blacklist.** Define what's allowed, reject everything else. Blacklists always miss something.
- **Enforce type, length, range, and format at the boundary.** An email field should reject a 10MB string before it hits any logic. An age field should reject negative numbers and strings.
- **Fail closed.** If validation is ambiguous, reject the input. Don't try to "fix" or "clean" malformed input and pass it through.

## Database Queries

- **Parameterize all queries. No exceptions.** No string concatenation. No template literals. No f-strings. Use prepared statements or your ORM's parameterized methods.
- This applies to SQL, NoSQL (MongoDB query injection is real), GraphQL, LDAP, and any query language.
- ORMs are not magic — raw queries through an ORM still need parameterization.

## Output Encoding

- **Encode output for its rendering context.** The same data needs different encoding depending on where it appears:
  - HTML body → HTML-encode (`<` → `&lt;`)
  - HTML attributes → attribute-encode (quote and encode)
  - JavaScript → JS-encode (or use JSON.stringify, never template into script tags)
  - URLs → URL-encode (`encodeURIComponent`)
  - SQL → parameterize (never encode manually)
  - CSS → CSS-encode or avoid dynamic CSS values entirely
  - Markdown, CSV, XML, shell commands — each has its own escaping rules
- **Never inject raw user content into any output context.**

## File Uploads

- Validate MIME type by content inspection (magic bytes), not just the extension or `Content-Type` header.
- Restrict to explicitly allowed types. Reject everything else.
- Limit file size at the reverse proxy / framework level, not just application code.
- Never serve uploads from the same origin as the application. Use a separate domain or CDN with `Content-Disposition: attachment`.
- Never let user input determine the storage path or filename. Generate random filenames. Resolve canonical paths and verify they're within the allowed directory.
- Strip EXIF and metadata from images before storage if privacy matters.
- Scan for malware if the use case warrants it.
