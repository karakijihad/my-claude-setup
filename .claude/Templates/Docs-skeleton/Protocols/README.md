# Project Protocols

Project-specific protocol overrides go here. **Rare.** Prefer to follow the global protocols in `~/.claude/Docs/Protocols/`.

Only add a file here when this project genuinely needs to diverge from a global protocol — e.g., a regulated environment requires stricter-than-default auth rules, or a legacy codebase needs a documented exception to the testing rules.

Each file here should:

1. Name the global protocol it overrides.
2. State which specific rules are overridden and what replaces them.
3. Explain why (incident, regulation, architectural constraint).

If you're tempted to add a file here for convenience rather than necessity, don't.
