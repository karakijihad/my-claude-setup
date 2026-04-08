#!/bin/bash
# UserPromptSubmit hook.
# Always injects brevity rule. Injects protocol reminder on keyword match.

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""' 2>/dev/null || echo "")

BREVITY="Brevity rule — prose only (explanations, status updates, questions, acknowledgments): no preamble, no filler, no closing summaries, never restate the request. This rule does NOT apply to code, commands, file paths, file contents, or any technical output — keep those complete and unabridged."

PROTOCOL=""

if echo "$PROMPT" | grep -qiE "security|auth|password|token|secret|sql|inject|xss|csrf|vulnerab|endpoint|api.key|hash|encrypt|sanitiz"; then
  PROTOCOL="Protocol reminder: Read ~/.claude/Docs/Protocols/SecurityProtocol.md before writing any security-relevant code."
elif echo "$PROMPT" | grep -qiE "\bgit\b|commit|branch|push|merge|rebase|stash|cherry.pick"; then
  PROTOCOL="Protocol reminder: Read ~/.claude/Docs/Protocols/GitProtocol.md before any git operations."
elif echo "$PROMPT" | grep -qiE "test|spec\b|coverage|jest|pytest|unittest|vitest|\be2e\b"; then
  PROTOCOL="Protocol reminder: Read ~/.claude/Docs/Protocols/TestingProtocol.md before writing or modifying tests."
elif echo "$PROMPT" | grep -qiE "\bagent\b|delegate|subagent|parallel.task|spawn"; then
  PROTOCOL="Protocol reminder: Read ~/.claude/Docs/Protocols/AgentProtocol.md before delegating to sub-agents."
elif echo "$PROMPT" | grep -qiE "compaction|token.limit|long.session|context.limit|degraded"; then
  PROTOCOL="Protocol reminder: Read ~/.claude/Docs/Protocols/ContextProtocol.md to manage context."
elif echo "$PROMPT" | grep -qiE "feedback|correction|update.rule|update.protocol|wrong.approach"; then
  PROTOCOL="Protocol reminder: Read ~/.claude/Docs/Protocols/FeedbackProtocol.md before updating any protocol."
fi

if [ -n "$PROTOCOL" ]; then
  echo "{\"additionalContext\": \"$BREVITY\n\n$PROTOCOL\"}"
else
  echo "{\"additionalContext\": \"$BREVITY\"}"
fi

exit 0
