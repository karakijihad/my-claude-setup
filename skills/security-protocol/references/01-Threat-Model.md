# 1. Threat Assessment â€” Do This First

> Part of [Security Protocol](../SKILL.md). Read before starting any new feature, endpoint, or phase.

Before writing code for any feature, endpoint, or phase â€” answer these:

- What does this feature expose? (endpoints, file access, user input, auth, data, third-party integrations)
- Who can reach it? (anonymous users, authenticated users, admins, internal services, automated bots)
- What's the worst thing an attacker could do with it?
- What's the blast radius if this component is compromised?
- What trust boundaries does data cross? (client â†’ server, service â†’ service, server â†’ database, server â†’ third-party)

If you can't answer these, stop and figure it out before coding. Assumptions here become vulnerabilities later.

## For AI-agent workflows, also answer:

- What permissions does the agent need to complete this task? (And is anything broader being granted?)
- What external content will the agent ingest, and could any of it be attacker-controlled?
- What's the blast radius if the agent is prompt-injected mid-task?

See [07-AI-Agents.md](./07-AI-Agents.md) for agent-specific threat model guidance.
