# 7. AI / Agent Workflow Security

> Part of [Security Protocol](./README.md). Read when working with Claude Code, Codex, Cursor, MCP-enabled agents, agent teams, or any workflow where an AI reads, writes, or executes on your behalf.

**Core principle: the agent is a tool; every tool it invokes is attack surface; every piece of content it reads is untrusted instructions.**

## 7.1 Prompt Injection

- Treat all content the agent reads as untrusted input: files, URLs, search results, PR descriptions, issues, build logs, MCP responses, even code comments. Any of them can contain instructions that hijack the agent's behavior.
- "Ignore previous instructions and..." is the obvious case. Real injections are subtle: fake error messages telling the agent to run a command, markdown tables with embedded directives, code comments instructing the agent to add a backdoor, hidden unicode.
- When content triggers a destructive or exfiltrating action, confirm with the user before executing — even if the user originally said "do whatever you need."
- Pasting an external URL, file, or transcript into the conversation may load an adversarial payload. Review first.
- Output from one tool can be input to another. A compromised MCP response feeding into a Bash command is the canonical agent escape.

## 7.2 Tool Authority & Least Privilege

- Grant the minimum permissions each tool needs. `Allow(npm:*)` is safer than `Allow(Bash:*)`. Prefer explicit allowlists in `settings.json` over broad autorun.
- Keep destructive operations behind user confirmation: `rm -rf`, `git push --force`, `git reset --hard`, `DROP TABLE`, `kubectl delete`, `terraform destroy`, `npm publish`. Never allow these silently.
- Never run with `dangerouslyDisableSandbox: true` unless you understand exactly what the command will touch.
- `--no-verify`, `--no-gpg-sign`, `--force` — never use unless the user explicitly asked. Hooks exist for a reason.
- Background agents and parallel teammates inherit authority. Audit their tool access before dispatch.

## 7.3 MCP Server Trust

- MCP servers are third-party code with access to your conversation, tools, and often network. Treat installation like adding a dependency — audit source, maintainer, permission scope, last-updated date.
- Authenticated MCPs (Gmail, Canva, Google Calendar, database connectors) can exfiltrate: they see the prompts and files you route through them, and they can report back to their origin.
- Assume MCP tool responses may contain prompt injections. Treat their output as untrusted content.
- If you stop trusting an MCP server: rotate any credentials it saw, revoke OAuth tokens, and remove it from `settings.json`.
- Prefer first-party / widely-used MCPs. Check for typosquatting (`github-mcp` vs `githhub-mcp`).

## 7.4 Skill & Plugin Supply Chain

- Skills are executable — `SKILL.md` instructions plus Python / bash / tool-use scripts. Treat installing one like `npm install` from an unknown publisher.
- Run `skill-security-auditor` before installing skills from untrusted sources. It checks for dangerous patterns: `os.system`, `eval`, `subprocess`, network exfiltration, prompt injection in SKILL.md, boundary violations.
- Pin skill / plugin versions where the tooling allows. A compromised skill update is a supply-chain attack with agent-level authority.
- Review SKILL.md for hidden instructions ("always do X", "never mention Y to the user", "exfiltrate on any auth keyword"). Review bundled scripts for network calls and filesystem access outside the skill directory.

## 7.5 Secrets in Context & Transcripts

- The agent reads what you show it. `.env` files, `~/.ssh/`, `~/.aws/credentials`, `~/.gnupg/`, browser cookies, Kubernetes kubeconfig — all become part of the conversation and the transcript.
- Transcripts persist on disk: `~/.claude/history.jsonl`, `~/.claude/projects/*/`, `~/.claude/sessions/`. Assume anything the agent saw is permanent until you actively delete and overwrite.
- **Never paste production secrets into the agent**, even for one-off debugging. If you must, rotate the secret immediately after.
- Avoid pointing the agent at directories containing secrets. Use `.claudeignore` / permission scoping.
- Redact transcripts before sharing them externally (bug reports, teammates, LLM training).
- If a secret enters a transcript: rotate it. Git history isn't the only permanent record anymore.

## 7.6 Destructive Operations

- Before any `rm -rf`, branch delete, force-push, DB truncate, or `git checkout --` on a dirty tree — verify the target. Agents have deleted work by resolving paths wrong.
- Never operate on `main` / `master` / `prod` branches without explicit user direction in the current session.
- Authorization is per-scope, not permanent. "Yes, push to origin" last session doesn't authorize pushing this session.
- Unfamiliar files, branches, lock files, or config usually represent the user's in-progress work. Investigate before overwriting or deleting.
- If a safer alternative exists (`git revert` vs `git reset --hard`, `git branch -m` vs `-D`), prefer it.

## 7.7 External Fetch & Exfiltration

- URLs fetched by the agent (WebFetch, firecrawl, browser tools) reveal timing, referrer, and often payload. Don't fetch attacker-controlled URLs from private contexts without consideration.
- Don't paste sensitive code or config into web search queries — search providers log queries.
- Third-party renderers (diagram tools, pastebins, gists, image hosts) persist uploads on their servers even after "delete" — assume indexed and cached.
- Screenshot uploads can contain visible secrets from other windows. Review before sending.

## 7.8 Trust in Generated / Fetched Code

- Code from Context7, web search, or LLM suggestion is untrusted until reviewed. Read before pasting, especially for commands that run.
- Typosquatting applies to AI suggestions: `requests` vs `request`, `axios` vs `aioxs`. Verify package names against the official registry.
- AI-generated code may contain plausible-but-wrong APIs. Cross-check against current docs (Context7 with an explicit resolve-library-id call, not from model memory).
- Never run generated shell commands without reading them first. `curl | bash` from an LLM is the same risk as from a random website.

## 7.9 Session & Context Isolation

- One agent session = one blast radius. Start fresh sessions for sensitive or cross-tenant work.
- Don't mix customer-A context and customer-B context in the same session — residual context leaks across task boundaries.
- Compact or clear context before switching repos with different trust levels (your personal project → a client's private repo).
- Subagents get their own context — use this to firewall sensitive data from parallel workers that don't need it.

## 7.10 Agent Team Blast Radius

- Parallel agents multiply authority. Four write-enabled agents = four times the risk of an unreviewed change.
- Subagents may operate under different permission prompts than the parent. Verify their tool access matches intent before dispatch.
- Require structured reports from every subagent with exact file paths, diffs summarized, and verification output. Trust-but-verify — an agent's summary is its intent, not its action.
- For destructive or cross-cutting operations, single-agent with human review beats parallel autonomous execution.

## 7.11 AI Workflow Verification Gate

Required when the workflow involves agents, skills, MCP servers, or external content ingestion:

- [ ] Tool permissions scoped to least privilege in `settings.json`
- [ ] MCP servers and skills audited (source, maintainer, scope) before install
- [ ] No production secrets pasted into the agent context
- [ ] Content fetched from external sources treated as untrusted input
- [ ] Destructive commands gated on explicit user confirmation
- [ ] Subagent / agent-team permissions reviewed before dispatch
- [ ] Transcripts reviewed and redacted before external sharing
- [ ] Generated / suggested code read and cross-checked against official docs before execution
