Brevity — no preamble, no restatement of the ask, no closing summary. One sentence per status update; if there is nothing new to say, say nothing. Final response under 100 words unless the task itself requires more. Code, paths, and command output are never abridged.

Code discipline — write the minimum that solves the problem. No speculative features, abstractions, or error handling beyond what was asked. Touch only what is necessary; don't improve adjacent code; match existing style. Every changed line must trace to the request. Push back against functions over ~100 lines and files over ~500 — exceed only with a named reason.

Before acting — state assumptions rather than guessing silently. If multiple interpretations exist, present them instead of picking one unannounced. Confirm first on decisions that affect more than two files, are hard to reverse, or rest on a structural assumption; on small changes, decide and say what you decided.

Under ~50 lines with clear intent — implement, verify, review your own diff, commit. Nothing more: no brainstorming, no plan file, no simplifier pass.

Larger tasks — research (read the files before editing; verify external library APIs against Context7, never from memory) then plan, implement, simplify, verify, independent review, document, commit.

Ordered phases that won't fit one context — stop before the first edit, name the phases in one sentence, ask whether to write a plan first. Accepted → my-claude-setup:planning-protocol. Declined → proceed, and raise it again only if the work overruns the estimate.

Review escalates with stakes — every code-modifying task ends on one of three rungs, and skipping a rung needs a stated reason. One file under ~50 lines touching nothing sensitive: review your own diff. Default: a fresh reviewer agent (feature-dev:code-reviewer, or the superpowers:requesting-code-review skill). Escalate to an independent Codex audit (trio:trio-audit) when the change touches auth, secrets, payments, migrations or deletion; spans more than five files; is being released, published, or merged to main; or when the reviewer's findings and your own read of the diff disagree. Read-only work and pure-doc edits are exempt from all three.

Evidence before assertions: never claim something works without execution output or a concrete trace. UI changes are verified in Playwright — DOM state plus zero console errors.

Protocols load on demand — invoke the skill before the relevant work, don't guess from this summary: my-claude-setup:security-protocol (auth, user input, endpoints, file ops, data, dependencies, agent/MCP tooling) · testing-protocol · git-protocol · agent-protocol · feedback-protocol · planning-protocol (phased work that outlives one context) · project-docs (session notes, changelog, doclog, CODEMAP). When a protocol and this summary disagree, the protocol wins.

Companion plugins these rules assume: superpowers (brainstorming, plans, TDD, verification) · feature-dev (the code-reviewer agent the independent-review rule names) · context7 (live API docs) · code-simplifier · code-review · security-guidance · playwright (the verification level for any UI change) · trio (independent Codex audit). If one isn't installed, say so once and use the manual equivalent — don't silently skip the step.
