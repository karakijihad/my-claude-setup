#!/bin/bash
# SubagentStop. The whole of the delegation-verification feature.
#
# Why a hook at all. agent-protocol has always said a sub-agent's report must
# carry pasted verify output, and prose could not make it so: the orchestrator
# reads a confident report, sees `done`, and integrates work nothing ran. The
# same reasoning that moved the destructive-command rule into guard.sh — a rule
# that has to fire when the work already feels finished loses to context
# pressure.
#
# Exit 2 is the documented block for this event, and stderr is fed back to the
# agent as a system message so it can react. That is the second sanctioned use
# of exit 2 in this plugin; every other path here exits 0.

IFS= read -r -d '' INPUT
. "$(dirname "$0")/lib-parse.sh"

parse_stop

# Set once this hook has already blocked this stop. Blocking again is how a hook
# loops an agent forever, so a second pass is always allowed through — one
# nudge, then the orchestrator owns the judgement.
[ -n "$ACTIVE" ] && exit 0
[ -z "$MSG" ] && exit 0

# Read the four fields of agent-protocol's report block out of the final
# message. Sections, not lines: `Verify output:` is normally a label followed by
# a fenced block, so anything that only looked at the label's own line would
# call every real report empty.
#
# The gate is deliberately narrow. No `Status:` at all means the agent is not
# using the protocol and this hook has no opinion. `Changed:` empty or `none`
# means a read-only agent — Explore, a reviewer, a trio lens — which holds no
# files and has nothing to verify. Only a `done` that claims changed files is
# asked for evidence.
#
# A label at the start of a line always ends the open section, including one
# this hook does not recognise. Letting an unrecognised header fall through to
# the accumulator instead was a hole straight through the gate: an agent
# writing `- **Note:** could not run the tests here` under an empty
# `Verify output:` padded that section past the evidence threshold with the
# text of its own excuse, and the report passed. Requiring the label to start
# the line is what keeps a `**PASS:**` inside pasted output from closing a
# section that is genuinely still open.
#
# The label itself is matched loosely on purpose: `**Label:**`, `**Label**:`
# (colon outside the bold), `__Label:__`, and plain `Label:` with no bold at
# all are all the same field to an agent that formats reports by hand. The
# whitelist below is what stays strict — a header is only ever "status",
# "changed", "verify output" or "assumptions". Any other *bolded* label closes the
# open section like the unrecognised-header case above; an unbolded one is body
# text, because pasted output is full of `PASS: 10` and `Error: x` lines.
# A report that bolds its headers bolds all of them, so its style is read off
# its *first* header — once that is bolded, an unbolded `Status: 200 OK` line is
# pasted output, not a header reopening a section. First, not any: scanning the
# whole message let a bolded label inside pasted output switch a plain report's
# real headers off and wave an empty verify output through.
BOLD=0
FIRST=$(printf '%s' "$MSG" | grep -m1 -iE '^[[:space:]]*([-*][[:space:]]+)?(\*\*|__)?(status|changed|verify output|assumptions)(\*\*|__)?:')
case "$FIRST" in *'**'*|*__*) BOLD=1 ;; esac
VERDICT=$(printf '%s' "$MSG" | awk -v bold="$BOLD" '
  /^[[:space:]]*([-*][[:space:]]+)?(\*\*|__)?[A-Za-z ]+(\*\*|__)?:(\*\*|__)?/ {
    match($0, /(\*\*|__)?[A-Za-z ]+(\*\*|__)?:(\*\*|__)?/)
    raw = substr($0, RSTART, RLENGTH)
    lab = raw
    gsub(/\*\*|__/, "", lab)
    sub(/:$/, "", lab)
    sub(/^[[:space:]]+/, "", lab)
    sub(/[[:space:]]+$/, "", lab)
    lab = tolower(lab)
    if ((raw ~ /\*\*|__/ || !bold) && (lab == "status" || lab == "changed" || lab == "verify output" || lab == "assumptions")) {
      sec = lab
      body[sec] = body[sec] " " substr($0, RSTART + RLENGTH)
    } else if (raw ~ /\*\*|__/) {
      sec = ""
    } else if (sec != "") {
      # An unbolded `PASS: 10` is pasted output, not a header. Only a bolded
      # label or one of the four names above may close a section.
      body[sec] = body[sec] " " $0
    }
    next
  }
  sec != "" { body[sec] = body[sec] " " $0 }
  END {
    st = tolower(body["status"]); gsub(/[^a-z]/, "", st)
    if (st !~ /^done/) exit
    ch = tolower(body["changed"]); gsub(/[^a-z0-9]/, "", ch)
    if (ch == "" || ch == "none" || ch == "na" || ch == "nochanges") exit
    # Two tests, and deliberately not a length test. A length floor was wrong in
    # both directions: it blocked `0 errors` and `OK`, which are what a passing
    # tsc or linter actually prints, while `could not run the command` sailed
    # through at 26 characters — the excuse satisfying the check it was excusing.
    #
    # So: the field is empty or a placeholder, or it says in words that the
    # command did not run. The verb is required in the second test — a bare
    # "cannot" or "could not" appears in real compiler output, and a report whose
    # verify output is a compiler error is a failed verification the orchestrator
    # should see, not a malformed report to bounce.
    v = tolower(body["verify output"])
    ph = v; gsub(/[^a-z0-9]/, "", ph)
    if (ph == "" || ph == "none" || ph == "na" || ph == "tbd" || ph == "todo" || ph == "pending") {
      print "BLOCK"; exit
    }
    # Anchored to the start of the field, not matched anywhere in it. Unanchored,
    # `suite: 2 tests did not run` and `certificate unverified` were blocked —
    # both pasted evidence that a command DID run. An agent explaining itself
    # leads with the excuse; real output has those words mid-stream. Erring
    # toward letting output through is deliberate: a false block costs a wasted
    # round and teaches rewording, which is worse than the gate this defends.
    gsub(/[^a-z]+/, " ", v)
    if (v ~ /^ *(the|this|it|i|we)? *(command|change|suite|tests?|verification)? *(could not|couldn t|cannot|can t|unable to|did not|didn t|was not|has not|failed to) (run|verify|verified|execute|invoke)/ ||
        v ~ /^ *(not verified|unverified|no verification)/) print "BLOCK"
  }
')

[ "$VERDICT" != "BLOCK" ] && exit 0

echo "Report claims done with changed files but carries no verify output. Run the verify command from your brief and paste its actual output into the Verify output field. If you cannot run it, report partial and say why — do not report done." >&2
exit 2
