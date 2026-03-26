# Context Management Protocol

> Referenced by `CLAUDE.md`. Read this when sessions run long, context approaches limits, or agent output starts degrading.
> Applies to all Claude Code sessions — main context, sub-agents, and agent teams.

**Core principle: a lean context produces better results than a full one.**

---

## 1. Why Context Management Matters

As context usage increases, instruction-following quality degrades uniformly — Claude doesn't just ignore newer instructions, it begins to ignore all of them, including CLAUDE.md rules and protocol references. A session at 80% context follows your rules significantly worse than one at 30%.

---

## 2. Compaction Rules

- **Compact proactively at ~65% context usage.** Don't wait for visible degradation — by then quality has already dropped.
- **Use manual `/compact` with preservation instructions** rather than relying on auto-compaction, which can't know what you care about.
- **Preservation template:** When compacting, always include:

```
/compact Preserve: current plan and its status, list of all modified files, current test status (passing/failing), active blockers, and any unresolved user questions.
```

- **Standing compaction instruction** (add to CLAUDE.md for your project): `When compacting, always preserve the full list of modified files, current test status, the active plan, and any pending user decisions.`

---

## 3. Session Hygiene

- **Use `/clear` between unrelated tasks** in the same session. Residual context from a previous task pollutes the next one.
- **One objective per session** for complex work. If you're doing a feature implementation, don't also debug an unrelated issue in the same session.
- **Don't fight context bloat with more context.** If you find yourself re-explaining things Claude should already know, the session is too long — compact or start fresh.
- **Start complex tasks in Plan mode.** Planning consumes less context than implementation. Lock in the plan, then switch to Normal/Auto-Accept for execution.

---

## 4. Sub-Agent Context

- **Prefer fresh sub-agent sessions** for exploration and analysis. Sub-agents get their own context window — use this to keep the main context lean.
- **Don't pass unnecessary context to sub-agents.** Give them the specific task and the specific files they need, not a dump of everything.
- **Sub-agents should return concise reports**, not raw output. The structured task report format (see AgentProtocol.md) is designed to carry maximum information in minimum tokens.

---

## 5. Agent Team Context

- **Each teammate has independent context** — this is a feature, not a limitation. Let them work in isolation and report back.
- **The lead's context is the bottleneck.** The lead receives all teammate reports. If four teammates each return 2000 tokens of report, that's 8000 tokens of lead context consumed. Keep reports concise.
- **Compact the lead's context** between rounds of delegation if running multiple sequential batches.

---

## 6. Warning Signs

Recognize these as context degradation signals:

- Claude ignores rules in CLAUDE.md that it was following earlier in the session.
- Claude asks questions that were already answered earlier.
- Code quality drops — more bugs, less adherence to style, speculative additions.
- Claude starts "summarizing" what it's about to do instead of doing it.
- Agent reports get vague ("everything looks good" instead of specific verification output).

**When you see these: compact immediately or start a fresh session.**

---

## 7. Context Budget Guidelines

| Task complexity | Recommended approach |
|----------------|---------------------|
| Quick fix (<50 lines) | Single session, no compaction needed |
| Medium feature (1-5 files) | Single session, compact once mid-way |
| Large feature (5+ files) | Plan in one session, implement in a fresh session with the plan file |
| Multi-day project | Fresh session each day, session notes carry context between days |
| Agent team work | Delegate mode on lead, fresh teammates per batch |

---

*This document is the single source of truth for context management. If CLAUDE.md contradicts it, this file wins.*
