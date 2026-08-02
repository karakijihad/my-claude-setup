#!/bin/bash
# SessionStart dispatcher.
#
# The core rules are emitted by session-start.py, because building a large
# multi-line JSON string in bash is a quoting minefield. But a missing Python
# would then cost the session *every* resident rule — a worse failure than the
# old CLAUDE.md had, which loaded regardless of interpreters. So: try Python,
# and fall back to a compact core rather than emitting nothing.

DIR="$(dirname "$0")"

if OUT=$(bash "$DIR/py.sh" "$DIR/session-start.py" 2>/dev/null) && [ -n "$OUT" ]; then
  printf '%s\n' "$OUT"
  exit 0
fi

# No Python. jq can still JSON-escape the real policy from the same core.md that
# session-start.py reads, so the full core survives on any machine with either
# tool — and the text below is not a second copy to keep in sync.
if command -v jq >/dev/null 2>&1 && [ -r "$DIR/core.md" ]; then
  if OUT=$(jq -Rs '{additionalContext: .}' < "$DIR/core.md" 2>/dev/null) && [ -n "$OUT" ]; then
    printf '%s\n' "$OUT"
    exit 0
  fi
fi

# Neither interpreter. This is the only place the policy is restated, and it is
# deliberately reduced — keep it short rather than trying to mirror core.md.
printf '%s\n' '{"additionalContext":"Brevity: no preamble, no restatement of the ask, no closing summary; under 100 words unless the task needs more. Code discipline: write the minimum that solves the problem, touch only what is necessary, every changed line traces to the request. Confirm first on anything affecting more than two files or hard to reverse. Under ~50 lines: implement, verify, independent review, commit. Every code-modifying task ends with a fresh reviewer agent. Evidence before assertions. Protocol skills load on demand: my-claude-setup:security-protocol, testing-protocol, git-protocol, agent-protocol, feedback-protocol, project-docs. (Python was unavailable, so this is the reduced core — install Python 3 for the full rules.)"}'
exit 0
