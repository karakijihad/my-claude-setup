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

**This is enforced, not requested.** `hooks/subagent-verify.sh` fires on `SubagentStop` and
reads the report itself: a `done` that lists changed files but whose **Verify output** is
empty, a placeholder, or a sentence saying the command didn't run is blocked, and the agent
resumes to produce one. So a brief that omits **Verify with** doesn't produce a lax agent — it
produces a stuck one.

It judges the *report*, not the transcript — an agent's own `Changed: none` is taken at its
word, because the transcript is written asynchronously and its line schema is undocumented.
That makes this a gate against forgetting to verify, not against an agent that misreports. The
orchestrator still reads what came back.

## Reading reports

Check each report's verify output *before* dispatching anything that depends on it, and run
the whole project's verify yourself at the end. Separately-green does not compose; the hook
proves each agent ran its own command, not that the pieces fit.

Non-trivial assumptions go to the user before the commit, not after.

## The loop

With a written plan, `superpowers:subagent-driven-development` owns the execution loop.
Without one, dispatch per the brief above and integrate yourself.
