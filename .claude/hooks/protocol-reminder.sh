#!/bin/bash
# Injects a protocol reminder into context when the user's prompt contains relevant keywords.
# Fires on UserPromptSubmit. Silent when no match.

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""' 2>/dev/null || echo "")

if echo "$PROMPT" | grep -qiE "security|auth|password|token|secret|sql|inject|xss|csrf|vulnerab|endpoint|api.key|hash|encrypt|sanitiz"; then
  echo '{"additionalContext": "Protocol reminder: Read ~/.claude/Docs/Protocols/SecurityProtocol.md before writing any security-relevant code."}'
elif echo "$PROMPT" | grep -qiE "\bgit\b|commit|branch|push|merge|rebase|stash|cherry.pick"; then
  echo '{"additionalContext": "Protocol reminder: Read ~/.claude/Docs/Protocols/GitProtocol.md before any git operations."}'
elif echo "$PROMPT" | grep -qiE "test|spec\b|coverage|jest|pytest|unittest|vitest|\be2e\b"; then
  echo '{"additionalContext": "Protocol reminder: Read ~/.claude/Docs/Protocols/TestingProtocol.md before writing or modifying tests."}'
elif echo "$PROMPT" | grep -qiE "\bagent\b|delegate|subagent|parallel.task|spawn"; then
  echo '{"additionalContext": "Protocol reminder: Read ~/.claude/Docs/Protocols/AgentProtocol.md before delegating to sub-agents."}'
elif echo "$PROMPT" | grep -qiE "compaction|token.limit|long.session|context.limit|degraded"; then
  echo '{"additionalContext": "Protocol reminder: Read ~/.claude/Docs/Protocols/ContextProtocol.md to manage context."}'
elif echo "$PROMPT" | grep -qiE "feedback|correction|update.rule|update.protocol|wrong.approach"; then
  echo '{"additionalContext": "Protocol reminder: Read ~/.claude/Docs/Protocols/FeedbackProtocol.md before updating any protocol."}'
fi

exit 0
