#!/bin/bash
# UserPromptSubmit hook. Reinforces brevity, which decays over a long session
# when it is only stated once at startup.
#
# Deliberately does not read stdin or spawn an interpreter: keyword-to-protocol
# routing used to live here, and is now handled by the skills' own descriptions.
# One bash process, one printf, nothing to parse.

printf '{"additionalContext":"Brevity: no preamble, no restatement of the ask, no closing summary. Prose only — code, paths, and command output stay unabridged."}\n'
exit 0
