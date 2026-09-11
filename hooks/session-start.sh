#!/bin/bash
# SessionStart dispatcher.
#
# The core rules are emitted by session-start.py, because building a large
# multi-line JSON string in bash is a quoting minefield. But a missing Python
# would then cost the session *every* resident rule — a worse failure than the
# old CLAUDE.md had, which loaded regardless of interpreters. So: try Python,
# and fall back to a compact core rather than emitting nothing.

DIR="$(dirname "$0")"

if OUT=$(bash "$DIR/py.sh" "$DIR/session-start.py" 2>/dev/null) && [ -n "$OUT" ]; then
  printf '%s\n' "$OUT"
  exit 0
fi

# No Python. jq can still JSON-escape the real policy from the same core.md that
# session-start.py reads, so the full core survives on any machine with either
# tool — and the text below is not a second copy to keep in sync.
if command -v jq >/dev/null 2>&1 && [ -r "$DIR/core.md" ]; then
  # The handoff too, or this branch silently drops the one feature whose whole
  # purpose is that work is not lost: the rules come back and the session that
  # just lost its context is left inferring what it had been doing.
  #
  # stdin is read only here, never before the Python attempt above — that child
  # inherits this script's stdin, and consuming the payload first would leave it
  # parsing an empty one. By the time control reaches this line Python has
  # already failed to run at all.
  #
  # Substring match rather than a parse, deliberately: there is no interpreter
  # on this path to parse with. Claude Code emits compact JSON, and a miss just
  # means no handoff — the same as before this block existed.
  IFS= read -r -d '' PAYLOAD
  EXTRA=""
  # compact and resume only, matching the Python path. `clear` is asked for and
  # is also just how a fresh start is made, so a handoff on disk may be finished
  # or stale; that branch announces it and asks rather than loading it. This
  # fallback has no interpreter to compute the file's age with, so it says
  # nothing at all rather than reinstating stale work silently.
  case "$PAYLOAD" in
    *'"source":"compact"'*|*'"source":"resume"'*)
      ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
      HF="$ROOT/Docs/HANDOFF.md"
      # Same two exclusions the Python path applies, for the same reasons: a
      # symlink reads whatever it points at, and a tracked handoff came from the
      # repository rather than from this machine's previous session.
      # `:(icase)` for the reason session-start.py documents: the -f test above
      # goes through a filesystem that ignores case on Windows and macOS, while
      # a git pathspec does not, so an exact-case query missed a repo that
      # committed `docs/handoff.md` and pasted it in as trusted local state.
      #
      # `head -c` matches the Python path's 4000-byte cap. Without it this branch
      # pasted the whole file however large it was — the cap is not a nicety, it
      # is the difference between a 30-line handoff and an entire repository
      # file arriving in context.
      if [ -n "$ROOT" ] && [ -f "$HF" ] && [ ! -L "$HF" ] \
         && ! git -C "$ROOT" ls-files --error-unmatch -- ':(icase)Docs/HANDOFF.md' >/dev/null 2>&1; then
        BODY=$(head -c 4000 "$HF")
        [ "$(wc -c < "$HF")" -gt 4000 ] \
          && END="--- handoff truncated at 4000 bytes; read the file for the rest ---" \
          || END="--- end handoff ---"
        # Whitespace-stripped, to match Python's `.strip()`. `[ -n "$BODY" ]`
        # alone is not the same test: a handoff holding only blank lines is
        # non-empty to bash, and would inject a hollow block naming a file that
        # says nothing.
        [ -n "$(printf '%s' "$BODY" | tr -d '[:space:]')" ] \
          && EXTRA=$(printf '\n\n--- %s ---\n%s\n%s' "$HF" "$BODY" "$END")
      fi ;;
  esac
  if OUT=$({ cat "$DIR/core.md"; printf '%s' "$EXTRA"; } \
           | jq -Rs '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: .}}' 2>/dev/null) \
     && [ -n "$OUT" ]; then
    printf '%s\n' "$OUT"
    exit 0
  fi
fi

# Neither interpreter. This is the only place the policy is restated, and it is
# deliberately reduced — keep it short rather than trying to mirror core.md.
printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Brevity: no preamble, no restatement of the ask, no closing summary; under 100 words unless the task needs more. Code discipline: write the minimum that solves the problem, touch only what is necessary, every changed line traces to the request. Confirm first on anything affecting more than two files or hard to reverse. Under ~50 lines: implement, verify, review your own diff, commit. Review escalates with stakes: your own diff on a small change, a fresh reviewer agent by default, an independent Codex audit when the change touches auth, secrets, migrations, or a release. Evidence before assertions. Ordered phases that will not fit one context: ask whether to write a plan first before the first edit. Fan out by file sets, not task count: parallel agents for reads that span more files than the answer needs, and for writes only when they split into disjoint file sets each with its own verify command. Protocol skills load on demand: my-claude-setup:security-protocol, testing-protocol, git-protocol, agent-protocol, planning-protocol, project-docs. (Python was unavailable, so this is the reduced core — install Python 3 for the full rules.)"}}'
exit 0
