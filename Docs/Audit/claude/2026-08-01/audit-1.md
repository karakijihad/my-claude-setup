# Claude Reconciliation — 2026-08-01

## Scope

Adjudication of Codex findings for run `2026-08-01T15-46-15`, five lenses
(auditor, security, tester, simplifier, consistency) over the whole plugin.

## Outcome

Trio's verdict is `ceiling_reached` — the loop stopped at its 2-pass cap, so the
run did not formally converge. **This is not the same as clean**, and Trio's
top-level `findings` array reads `0` in that state, which is easy to misread as
success. The pass-2 lenses reported 17 findings that the array never carried.

Adjudication of pass 2 was written to `.trio/runs/2026-08-01T15-46-15/pass-2/response.json`
after the run had already ended, so Trio could not ingest it. The auto-generated
version of this file therefore listed all 17 as open; corrected below by hand.

Across both passes: **31 findings — 27 fixed, 1 refuted, 3 declined.**

## Pass trail

| Pass | Findings | Fixed | Refuted | Declined |
| --- | --- | --- | --- | --- |
| 1 | 14 | 14 | 0 | 0 |
| 2 | 17 | 13 | 1 | 3 |

Pass 1's critical finding (`c1eb366a`, three lenses) was a genuine security-control
failure: `lib-parse.sh` selected an interpreter with `command -v`, so on a Windows
install where only `py -3` works, every field parsed empty and `guard.sh` skipped
destructive-command, secret-scan, and protected-file enforcement without a word.
Latent on the dev machine — the guard demonstrably blocked a live `rm -rf` there.

## Where we disagreed

| Finding | Codex said | Verdict | Basis |
| --- | --- | --- | --- |
| `6d853b84` | Windows paths bypass the protected-file and `.git` guards, because `basename "C:\repo\.env"` returns the whole path | **Refuted** | `guard.sh` runs under bash (`hooks.json` sets `"shell": "bash"`), and MSYS `basename` does split on backslashes — it returns `.env`. The `.git` case already carries an explicit backslash pattern. Fed exact bytes via a file, `C:\repo\.env` and `C:\repo\.git\config` both exit 2. Shell heredocs mangle the escaping, which is what produced an apparent bypass on first attempt. Fixtures added regardless — this is the primary platform and the behaviour was untested. |
| `e7e6d198` | The pass-1 mitigation (labelling git metadata untrusted) is insufficient; drop repository metadata entirely | **Accepted, and went further than pass 1** | Correct that a natural-language "untrusted" label is itself just more context, not a control. Commit subjects — arbitrary free text from whoever wrote the repo — are no longer emitted at all. Branch name kept: git ref rules keep it short and space-free, and `git log` is one tool call away. |
| `db2057a9` / `b8bee5e4` | Same NotebookEdit gap, rated major by one lens and minor by another | **Minor** | `NotebookEdit` only carries an `.ipynb` path, which will not collide with the `.env`/lockfile/`.git` rules. Fixed anyway; it was two lines. |
| `ed3be081` | Add a clean-environment test that runs the documented `py.sh` auditor launch | **Declined** | The mechanism that would regress — `py.sh`'s interpreter probe under stubbed `python`/`python3` — is already covered by `49bedd78`'s Windows-layout case. A second full run duplicates the guarantee on a suite already at ~4s per assertion. Verified by hand instead: exit 0. |
| `9fa3f43c` | The no-Python/no-jq fallback still holds a second policy copy; emit both paths from one data file | **Declined — not achievable** | That branch exists for a machine with neither interpreter, so there is no tool available to escape a data file into JSON. A literal string must exist somewhere. Duplication is now bounded to that one branch and marked deliberately reduced rather than a mirror. |

## What the audit did not find

Two issues surfaced outside the lenses and were fixed in the same work:

- `hooks/notify.sh` interpolated the unsanitized notification message into
  `osascript` source, so a `"` in a model-influenced message closed the AppleScript
  literal and `do shell script` followed. The PowerShell branch already sanitized;
  the macOS branch did not.
- The verification procedure in `CLAUDE.md` was un-runnable: its own `rm -rf /`
  fixture tripped `guard.sh`, blocking the command that verified `guard.sh`. This
  is the direct reason the repo had no test suite.

## Notable: five findings were defects in the fix

Pass 2 reviewed the pass-1 changes and found real problems in the test file written
to close pass 1's coverage gap — an unguarded `mktemp` that would write to `/py.sh`
on failure, a sanitizer assertion that recomputed the `tr` pipeline instead of
driving `notify.sh` (so deleting the sanitizer would have kept it green), and three
coverage gaps. The second pass earned its cost.

Two genuine pre-existing security bugs also came out of pass 2, both in the tool
whose job is to catch that class: `--skill` path traversal out of the clone
(`38c58267`) and credential disclosure from unredacted clone URLs (`dfb566a1`).

## Open findings

None fixed-pending. The three entries in the disagreement table above (`6d853b84`
refuted, `ed3be081` and `9fa3f43c` declined) are the only items not changed in code.

## Verification

- `bash hooks/test-hooks.sh` — 29 passed, 0 failed, exit 0
- `py_compile` clean on all three Python files
- `bash -n` clean on all seven shell scripts

The suite now covers the exact Windows interpreter layout behind pass 1's critical
finding: jq and `python`/`python3` stubbed to fail, only `py -3` real, asserting
`guard.sh` still blocks. That case failed when first written — `lib-parse.sh` was
trusting `command -v jq` the same way it had trusted `command -v python`, so a jq
that exists but cannot execute produced the identical silent fail-open. Fixed by
probing jq with a real parse before using it.
