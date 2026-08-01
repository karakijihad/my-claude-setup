#!/usr/bin/env python
"""SessionStart hook — the always-resident core.

Replaces the former ~/.claude/CLAUDE.md. Everything that is only sometimes
relevant lives in a protocol skill and loads on demand; only rules that must
hold before Claude has invoked anything belong here.

Invoked through py.sh, never as `python3` directly — see that script for why.
"""
import io
import json
import subprocess
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

CORE = """\
Brevity — no preamble, no restatement of the ask, no closing summary. One sentence per status \
update; if there is nothing new to say, say nothing. Final response under 100 words unless the \
task itself requires more. Code, paths, and command output are never abridged.

Code discipline — write the minimum that solves the problem. No speculative features, \
abstractions, or error handling beyond what was asked. Touch only what is necessary; don't \
improve adjacent code; match existing style. Every changed line must trace to the request. Push \
back against functions over ~100 lines and files over ~500 — exceed only with a named reason.

Before acting — state assumptions rather than guessing silently. If multiple interpretations \
exist, present them instead of picking one unannounced. Confirm first on decisions that affect \
more than two files, are hard to reverse, or rest on a structural assumption; on small changes, \
decide and say what you decided.

Under ~50 lines with clear intent — implement, verify, independent review, commit. Nothing more: \
no brainstorming, no plan file, no simplifier pass.

Larger tasks — research (read the files before editing; verify external library APIs against \
Context7, never from memory) then plan, implement, simplify, verify, independent review, \
document, commit.

Hard rule — every code-modifying task ends with a fresh reviewer agent \
(feature-dev:code-reviewer, or the superpowers:requesting-code-review skill). Read-only work and \
pure-doc edits are exempt. Evidence before assertions: never claim something works without \
execution output or a concrete trace. UI changes are verified in Playwright — DOM state plus \
zero console errors.

Protocols load on demand — invoke the skill before the relevant work, don't guess from this \
summary: my-claude-setup:security-protocol (auth, user input, endpoints, file ops, data, \
dependencies, agent/MCP tooling) · testing-protocol · git-protocol · agent-protocol · \
context-protocol · feedback-protocol · project-docs (session notes, changelog, doclog, CODEMAP). \
When a protocol and this summary disagree, the protocol wins.

Companion plugins these rules assume: superpowers (brainstorming, plans, TDD, verification) · \
feature-dev (the code-reviewer agent the independent-review rule names) · context7 (live API \
docs) · code-simplifier · code-review · security-guidance · trio (independent Codex audit). If \
one isn't installed, say so once and use the manual equivalent — don't silently skip the step."""


def git_context() -> str:
    """Branch and recent commits, or empty string outside a repo."""
    def run(*args: str) -> str:
        try:
            out = subprocess.run(
                ["git", *args], capture_output=True, text=True, timeout=5
            )
            return out.stdout.strip() if out.returncode == 0 else ""
        except Exception:
            return ""

    branch = run("branch", "--show-current")
    if not branch:
        return ""
    recent = run("log", "--oneline", "-3").replace("\n", " · ")
    return f"\n\nBranch: {branch}." + (f" Recent: {recent}" if recent else "")


def main() -> None:
    sys.stdin.read()  # drain payload; nothing in it is needed
    print(json.dumps({"additionalContext": CORE + git_context()}, ensure_ascii=False))


if __name__ == "__main__":
    main()
