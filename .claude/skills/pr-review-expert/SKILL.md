---
name: "pr-review-expert"
description: >
  Structured PR/MR review with blast radius analysis, security scanning, coverage delta,
  and breaking change detection. Use when: reviewing a PR, checking a diff before merge,
  "review PR #N", "check this MR", "is this safe to merge", "review my changes".
---

# PR Review Expert

Structured code review for GitHub PRs and GitLab MRs. Blast radius analysis, security scan, test coverage delta, breaking change detection.

## Workflow

### 1. Fetch Context

```bash
PR=123
gh pr view $PR --json title,body,labels,milestone,assignees | jq .
gh pr diff $PR --name-only
gh pr diff $PR > /tmp/pr-$PR.diff
```

### 2. Blast Radius Analysis

For each changed file, identify direct dependents, service boundaries, and shared contracts:

```bash
# Files importing changed modules
grep -r "from ['\"].*changed-module['\"]" src/ --include="*.ts" -l
grep -r "import changed_module" . --include="*.py" -l

# Cross-service check (monorepo)
gh pr diff $PR --name-only | cut -d/ -f1-2 | sort -u

# Shared types/schemas touched
gh pr diff $PR --name-only | grep -E "types/|interfaces/|schemas/|models/"
```

**Severity:** CRITICAL = shared library, DB model, auth middleware, API contract. HIGH = service used by >3 others, shared config. MEDIUM = single service internal. LOW = UI component, test, docs.

### 3. Security Scan

```bash
DIFF=/tmp/pr-$PR.diff

# SQL injection — raw query interpolation
grep -n "query\|execute\|raw(" $DIFF | grep -E '\$\{|f"|%s|format\('

# Hardcoded secrets
grep -nE "(password|secret|api_key|token|private_key)\s*=\s*['\"][^'\"]{8,}" $DIFF

# AWS keys
grep -nE "AKIA[0-9A-Z]{16}" $DIFF

# XSS vectors
grep -n "dangerouslySetInnerHTML\|innerHTML\s*=" $DIFF

# Auth bypass
grep -n "bypass\|skip.*auth\|noauth\|TODO.*auth" $DIFF

# Insecure hashing
grep -nE "md5\(|sha1\(|createHash\(['\"]md5|createHash\(['\"]sha1" $DIFF

# eval / exec
grep -nE "\beval\(|\bexec\(|\bsubprocess\.call\(" $DIFF

# Path traversal
grep -nE "path\.join\(.*req\.|readFile\(.*req\." $DIFF
```

### 4. Test Coverage Delta

```bash
CHANGED_SRC=$(gh pr diff $PR --name-only | grep -vE "\.test\.|\.spec\.|__tests__")
CHANGED_TESTS=$(gh pr diff $PR --name-only | grep -E "\.test\.|\.spec\.|__tests__")

echo "Source files changed: $(echo "$CHANGED_SRC" | wc -w)"
echo "Test files changed:   $(echo "$CHANGED_TESTS" | wc -w)"
```

Flag: new function without tests, deleted tests without deleted code, coverage drop >5%, auth/payments paths without 100% coverage.

### 5. Breaking Change Detection

```bash
# API route removals
grep "^-" $DIFF | grep -E "router\.(get|post|put|delete|patch)\("

# DB destructive operations
grep -E "DROP TABLE|DROP COLUMN|ALTER.*NOT NULL|TRUNCATE" $DIFF

# New env vars (might be missing in prod)
grep "^+" $DIFF | grep -oE "process\.env\.[A-Z_]+" | sort -u
```

### 6. Performance Impact

```bash
# N+1 patterns
grep -n "\.find\|\.findOne\|\.query\|db\." $DIFF | grep "^+" | head -20

# Heavy new deps
grep "^+" $DIFF | grep -E '"[a-z@].*":\s*"[0-9^~]' | head -20

# Missing await
grep -n "await.*await" $DIFF | grep "^+" | head -10
```

## Output Format

```
## PR Review: [PR Title] (#NUMBER)

Blast Radius: [severity] — [reason]
Security: [N findings (severity)]
Tests: Coverage delta [+/-N%]
Breaking Changes: [None / list]

--- MUST FIX (Blocking) ---
1. [Finding with file:line and fix]

--- SHOULD FIX (Non-blocking) ---
2. [Finding]

--- SUGGESTIONS ---
3. [Finding]

--- LOOKS GOOD ---
- [What's well done]
```

## Review Checklist

**Scope:** PR title accurate, description explains WHY, ticket linked, no scope creep, breaking changes documented.
**Blast Radius:** Importers checked, cross-service deps, shared schemas reviewed, new env vars in .env.example, migrations reversible.
**Security:** No hardcoded secrets, queries parameterized, inputs validated, auth on new endpoints, no XSS vectors, new deps checked for CVEs, no PII in logs, CORS configured.
**Testing:** New functions have tests, edge cases covered, error paths tested, no tests deleted without reason.
**Breaking Changes:** No endpoints removed without deprecation, no required fields added, no columns removed without two-phase plan.
**Performance:** No N+1 patterns, indexes for new queries, no unbounded loops, async correctly awaited.
