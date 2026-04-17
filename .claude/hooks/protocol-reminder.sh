#!/bin/bash
# UserPromptSubmit hook.
# Always injects brevity rule. Concatenates every matching protocol reminder.
# Uses python for JSON I/O so the hook works with or without jq on PATH.

BREVITY="Brevity rule — prose only (explanations, status updates, questions, acknowledgments): no preamble, no filler, no closing summaries, never restate the request. This rule does NOT apply to code, commands, file paths, file contents, or any technical output — keep those complete and unabridged."

INPUT=$(cat)

# Extract prompt field. Prefer jq if present; fall back to python; fall back to raw input
# (keyword search still works on the raw JSON string — the keys are not reserved words we match).
PY_PARSE='import json,sys,io; sys.stdin=io.TextIOWrapper(sys.stdin.buffer,encoding="utf-8"); sys.stdout=io.TextIOWrapper(sys.stdout.buffer,encoding="utf-8"); print(json.loads(sys.stdin.read() or "{}").get("prompt",""))'

if command -v jq >/dev/null 2>&1; then
  PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // ""')
elif command -v python >/dev/null 2>&1; then
  PROMPT=$(printf '%s' "$INPUT" | python -c "$PY_PARSE" 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
  PROMPT=$(printf '%s' "$INPUT" | python3 -c "$PY_PARSE" 2>/dev/null)
else
  PROMPT="$INPUT"
fi

REMINDERS=""
add() {
  if [ -z "$REMINDERS" ]; then REMINDERS="$1"; else REMINDERS="${REMINDERS}\n\n$1"; fi
}

SEC_BASE="~/.claude/Docs/Protocols/Security"
SEC_HIT=0

if echo "$PROMPT" | grep -qiE "sql|inject|sanitiz|xss|mongo.query|path.travers|mass.assign|file.upload"; then
  add "Protocol reminder: Read ${SEC_BASE}/02-Input.md — input validation, parameterized queries, output encoding, file uploads."
  SEC_HIT=1
fi

if echo "$PROMPT" | grep -qiE "\bauth\b|authn|authz|authoriz|password|jwt|oauth|\bsession\b|\btoken\b|api.key|idor|priv.escal|mfa"; then
  add "Protocol reminder: Read ${SEC_BASE}/03-Auth.md — authentication, authorization, sessions, JWT, API keys."
  SEC_HIT=1
fi

if echo "$PROMPT" | grep -qiE "\bsecret\b|\.env\b|pii|encrypt|decrypt|\bhash\b|hsts|tls\b|logging"; then
  add "Protocol reminder: Read ${SEC_BASE}/04-Data.md — secrets management, data in transit/rest, logging, errors, config."
  SEC_HIT=1
fi

if echo "$PROMPT" | grep -qiE "cors|csrf|rate.limit|\bendpoint\b|websocket|graphql|csp|x-frame"; then
  add "Protocol reminder: Read ${SEC_BASE}/05-API.md — rate limiting, CORS, CSRF, security headers, WebSocket, GraphQL."
  SEC_HIT=1
fi

if echo "$PROMPT" | grep -qiE "dependency|supply.chain|npm.audit|pip.audit|cargo.audit|lock.file|vulnerab|typosquat"; then
  add "Protocol reminder: Read ${SEC_BASE}/06-Dependencies.md — supply chain, package audit, lock files, typosquatting."
  SEC_HIT=1
fi

if echo "$PROMPT" | grep -qiE "prompt.inject|\bmcp\b|skill.install|agent.tool|claude.code|codex|cursor|subagent.permission|dangerouslydisable"; then
  add "Protocol reminder: Read ${SEC_BASE}/07-AI-Agents.md — prompt injection, tool authority, MCP trust, skill supply chain, destructive ops."
  SEC_HIT=1
fi

if [ "$SEC_HIT" = "0" ] && echo "$PROMPT" | grep -qiE "\bsecurity\b|vulnerab|threat"; then
  add "Protocol reminder: Read ${SEC_BASE}/README.md and jump to the relevant subfile."
fi

if echo "$PROMPT" | grep -qiE "\bgit\b|commit|branch|push|merge|rebase|stash|cherry.pick"; then
  add "Protocol reminder: Read ~/.claude/Docs/Protocols/GitProtocol.md before any git operations."
fi

if echo "$PROMPT" | grep -qiE "test|spec\b|coverage|jest|pytest|unittest|vitest|\be2e\b"; then
  add "Protocol reminder: Read ~/.claude/Docs/Protocols/TestingProtocol.md before writing or modifying tests."
fi

if echo "$PROMPT" | grep -qiE "\bagent\b|delegate|subagent|parallel.task|spawn"; then
  add "Protocol reminder: Read ~/.claude/Docs/Protocols/AgentProtocol.md before delegating to sub-agents."
fi

if echo "$PROMPT" | grep -qiE "compaction|token.limit|long.session|context.limit|degraded"; then
  add "Protocol reminder: Read ~/.claude/Docs/Protocols/ContextProtocol.md to manage context."
fi

if echo "$PROMPT" | grep -qiE "feedback|correction|update.rule|update.protocol|wrong.approach"; then
  add "Protocol reminder: Read ~/.claude/Docs/Protocols/FeedbackProtocol.md before updating any protocol."
fi

if [ -n "$REMINDERS" ]; then
  CONTEXT="${BREVITY}\n\n${REMINDERS}"
else
  CONTEXT="${BREVITY}"
fi

PY_EMIT='import json,sys,io; sys.stdin=io.TextIOWrapper(sys.stdin.buffer,encoding="utf-8"); sys.stdout=io.TextIOWrapper(sys.stdout.buffer,encoding="utf-8"); print(json.dumps({"additionalContext": sys.stdin.read()}, ensure_ascii=False))'

if command -v python >/dev/null 2>&1; then
  printf '%b' "$CONTEXT" | python -c "$PY_EMIT"
elif command -v python3 >/dev/null 2>&1; then
  printf '%b' "$CONTEXT" | python3 -c "$PY_EMIT"
elif command -v jq >/dev/null 2>&1; then
  printf '%b' "$CONTEXT" | jq -Rs '{additionalContext: .}'
else
  ESCAPED=$(printf '%b' "$CONTEXT" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk 'BEGIN{ORS="\\n"} {print}' | sed 's/\\n$//')
  printf '{"additionalContext":"%s"}\n' "$ESCAPED"
fi

exit 0
