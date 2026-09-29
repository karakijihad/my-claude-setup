---
name: agent-protocol
description: >
  Use before dispatching any agent, and when assessing what one reported back.
---

# Agent Protocol

The decision of *whether* to fan out is in the resident core: **by file sets, not task
count.** This skill is what that decision needs to execute — the brief you send, the report
you demand back, and how to read one.

**Dispatch rules.** One agent per file set, all of them sent in a single message so they run
concurrently. Never edit a file an agent holds: you are a writer too, and the merge has no
git behind it.

**Agent type, model and effort.** Work that writes code, gathers information or runs tests
goes to `my-claude-setup:worker`; advice to `my-claude-setup:advisor`, which never writes
code. The session-start line names both models and what to pass: the Agent tool's `model`
takes only an alias and overrides the id in settings, so the worker usually goes out with none.
Both cards run at effort high, fixed. A job that needs a stronger model: ask the operator
first. A model the operator names applies to that dispatch only; one they want from now on
goes into `.claude/settings.local.json`. Announce each dispatch in one line, model and effort
included. `general-purpose` has no effort of its own; don't delegate to it.

## The brief

Every dispatched agent gets all six fields. A missing field is how an agent invents scope.

```markdown
**Goal:** [one sentence — the outcome, not the steps]
**Files you may touch:** [explicit list; no globs]
**Files you must not touch:** [the sets held by sibling agents, and anything shared]
**Acceptance criterion:** [what makes this done, stated so it can fail]
**Verify with:** [the exact command, copy-pasteable]
**Report with:** [the block below — say "verbatim"]
```

Read-only agents (`Explore`, reviewers, `trio:trio-lens`) take the same brief minus the two
file-list fields: they hold nothing, so nothing collides.

## The report

```markdown
- **Status:** done | partial | blocked
- **Changed:** [each file created, modified or deleted]
- **Verify output:** [paste it — the command's actual output]
- **Assumptions:** [decisions made without asking; "none" is a valid answer]
```

`done` requires pasted verify output. Couldn't run the command → `partial`, and say why.
Needs something you don't have → `blocked`.

Nothing enforces this shape but you. The brief asks for the block; **you** are the check
that it came back.

## Reading reports

Read each report's verify output *before* dispatching anything that depends on it, and run
the whole project's verify yourself at the end. Separately-green does not compose.

An agent's `Changed: none` is its own claim. When it matters, `git status` costs nothing.

Non-trivial assumptions go to the user before the commit, not after.

## The loop

With a written plan, `superpowers:subagent-driven-development` owns the execution loop.
Without one, dispatch per the brief above and integrate yourself.
