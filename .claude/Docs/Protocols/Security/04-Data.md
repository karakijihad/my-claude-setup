# 4. Data Protection

> Part of [Security Protocol](./README.md). Read before handling secrets, PII, logs, or configuration.

## Secrets Management

- **Secrets (API keys, tokens, passwords, connection strings, encryption keys):** Never hardcoded. Never committed. Never logged. Never in error messages. Never in client bundles.
- Use `.env` files (gitignored) locally. Use a secrets manager (Vault, AWS Secrets Manager, GCP Secret Manager, etc.) in production.
- **If a secret was ever committed, rotate it immediately.** Git history is permanent. Rewriting history is unreliable. Assume it's compromised.
- Pre-commit hooks: Use tools like `git-secrets`, `trufflehog`, or `gitleaks` to catch secrets before they're committed.

## Data in Transit

- HTTPS everywhere. No exceptions. No mixed content.
- Set `Strict-Transport-Security` (HSTS) header with `max-age` of at least one year and `includeSubDomains`.
- Use TLS 1.2+ only. Disable older protocols.
- Certificate pinning for mobile apps or high-security APIs where appropriate.
- Internal service-to-service traffic should also be encrypted (mTLS or TLS).

## Data at Rest

- Encrypt PII and sensitive fields at the application or database level, not just disk encryption.
- Know your data classification. What's PII? What's sensitive? What's public?
- Don't store what you don't need. Minimize data collection.
- Have a retention and deletion policy. Actually enforce it. GDPR, CCPA, and similar regulations require this.
- Encryption keys: store separately from the data they protect. Rotate periodically.

## Logging

- **Never log:** passwords (even hashed), tokens, session IDs, credit card numbers, SSNs, full request/response bodies with sensitive fields, PII beyond what's necessary for debugging.
- Scrub or mask sensitive fields before logging. Log the structure, not the content.
- Centralize logs. Set retention policies. Restrict access to log systems.
- Structured logging (JSON) over unstructured text — makes it easier to filter and redact.

## Error Handling

- **Never expose to the client:** stack traces, database errors, internal file paths, SQL queries, system architecture details, dependency versions, or debug information.
- Log detailed errors server-side with correlation IDs.
- Return generic messages to users: "Something went wrong. Reference: abc-123."
- Different error detail levels per environment: verbose in development, minimal in production.

## Configuration Files

- `.env`, `.env.local`, `.env.production`, config files with secrets: **always in `.gitignore`**. Verify before every commit.
- Provide `.env.example` with dummy values for onboarding. Never real credentials.
- Database connection strings, API keys, signing secrets — all go through environment variables, never config files checked into source control.
