# Codex Audit — 2026-08-01

## Scope

Run `2026-08-01T15-46-15`, 2 pass(es). Lenses: auditor (ok), security (ok), tester (ok), simplifier (ok), consistency (ok). Codex ran read-only; it changed nothing.

## Executive Summary

Findings: 12 major, 5 minor.

## Findings

### Major

#### Windows paths bypass protected-file and .git guards

**Where** `hooks/guard.sh:59` · **Lens** auditor · **Id** `6d853b84`

**Evidence** basename "C:\repo\.env" returns the full backslash-delimited path, not .env, so lines 59-65 do not match it. The .git case at line 68 is likewise not covered by the POSIX-only fixtures in hooks/test-hooks.sh:61-68.

**Impact** On Windows, Edit, Write, or NotebookEdit can modify .env files, lockfiles, and files inside .git without the intended PreToolUse block.

**Correction** Normalize file paths before both case checks (for example, replace backslashes with slashes), then add Windows-path fixtures for .env, a lockfile, and .git.

#### Untrusted Git metadata remains injected into agent context

**Where** `hooks/session-start.py:56` · **Lens** security · **Id** `e7e6d198`

**Evidence** Repository-controlled branch and commit-subject text flows from git_context() (session-start.py:43-46) directly into additionalContext (session-start.py:63-64). The warning at session-start.py:51-56 is itself only natural-language context, so a malicious commit subject remains agent-visible instruction text.

**Impact** An attacker able to contribute repository metadata can prompt-inject the agent at session start and influence subsequent tool use or data handling.

**Correction** Do not include branch names or commit subjects in additionalContext. If repository metadata is needed, expose it only through an explicit, on-demand tool response and treat it as untrusted data.

#### Attacker-controlled --skill path can escape the cloned repository

**Where** `skills/skill-security-auditor/scripts/skill_security_auditor.py:966` · **Lens** security · **Id** `38c58267`

**Evidence** The untrusted CLI --skill value (skill_security_auditor.py:1033-1036) is appended directly to Path(tmp_dir) at 966. Absolute paths replace tmp_dir and ../ components escape it; the resulting path reaches scan_skill() at 1071, whose scanners recursively read files at 800, 929, and 937 and emit matching content snippets at 675 and 704.

**Impact** A maliciously supplied audit command can make the auditor recursively read arbitrary local directories and disclose portions of matching files, including user data or credentials, in its report.

**Correction** Require --skill to be a plain relative subdirectory name, reject absolute paths, traversal components, and glob syntax, then resolve it and verify it is contained within tmp_dir before scanning. Remove the unrestricted rglob fallback or apply the same containment validation to every match.

#### Clone errors disclose credentials embedded in repository URLs

**Where** `skills/skill-security-auditor/scripts/skill_security_auditor.py:961` · **Lens** security · **Id** `dfb566a1`

**Evidence** The user-supplied repository URL is accepted as args.path (skill_security_auditor.py:1029-1032), passed to git clone (954-959), and interpolated verbatim into an error message at 961 when cloning fails. HTTPS URLs may contain a username/password or access token.

**Impact** A transient clone failure can place repository credentials in terminal output, agent context, CI logs, or shared transcripts.

**Correction** Redact URL userinfo and sensitive query parameters before logging, and avoid printing raw git stderr unless it is similarly redacted.

#### Windows Python fallback remains untested

**Where** `hooks/test-hooks.sh:53` · **Lens** tester · **Id** `49bedd78`

**Evidence** The suite invokes guard.sh only with the ambient jq/Python environment (lines 20, 53-69); it never masks jq and failing python/python3 while exposing only a working `py -3` shim.

**Impact** A clean Windows installation can again parse every protected event as empty and fail open without the suite detecting it.

**Correction** Add an isolated PATH-based integration case with jq absent, failing python/python3 stubs, and only a working `py -3` shim; assert destructive Bash and protected file events exit 2.

#### Documented py.sh auditor launch remains unverified

**Where** `skills/skill-security-auditor/SKILL.md:27` · **Lens** tester · **Id** `ed3be081`

**Evidence** The new test suite contains no invocation of skill_security_auditor.py or of the AUDIT command documented at SKILL.md:27-40.

**Impact** The Windows-specific launcher guidance can regress while local `--help` checks using a normal interpreter remain green.

**Correction** Add a clean-environment command-level test with failing python3 and a working `py -3` shim, then run the documented py.sh command and assert a valid audit result.

#### Commit secret-blocking path has no test

**Where** `hooks/test-hooks.sh:58` · **Lens** tester · **Id** `d815ef2f`

**Evidence** guard.sh scans staged additions for value-shaped credentials and key material, but test-hooks.sh only tests a clean `git commit` allow at line 58; no test stages a secret and expects exit 2.

**Impact** Changes that disable, weaken, or bypass the commit secret scan pass all 22 assertions.

**Correction** Create an isolated temporary Git repository, stage representative value-shaped and token/key fixtures, invoke guard.sh with a commit command, and assert each is blocked.

#### Notify sanitizer assertion tests a duplicate implementation

**Where** `hooks/test-hooks.sh:77` · **Lens** tester · **Id** `3789e7ec`

**Evidence** Lines 76-80 recompute the tr/cut expression instead of invoking notify.sh with the malicious message; line 72 invokes notify.sh only with `build done`.

**Impact** notify.sh can remove or alter its sanitizer and the test still passes, allowing AppleScript or PowerShell source injection to return.

**Correction** Put a stub osascript or powershell.exe first on a temporary PATH, invoke notify.sh with the malicious message, and assert the argument passed to the backend contains no executable quote/backtick/dollar/backslash characters.

#### Fallback fixture can write outside its temporary directory

**Where** `hooks/test-hooks.sh:43` · **Lens** tester · **Id** `e12494b3`

**Evidence** `TMP=$(mktemp -d) && cp ...` does not stop the script when mktemp fails; line 44 then redirects to `$TMP/py.sh`, which is `/py.sh` when TMP is empty.

**Impact** On a system without a usable mktemp, running the suite writes outside the intended temporary directory and may alter a root-level file.

**Correction** Immediately validate that mktemp succeeded and that TMP is an existing directory; exit before any copy or redirect if it did not.

#### Companion configuration remains triplicated and divergent

**Where** `hooks/onboarding.py:18` · **Lens** simplifier · **Id** `a6acd798`

**Evidence** COMPANIONS is maintained in onboarding.py, core.md line 15 names the same plugins, and README.md lines 145-151 provides another install list. The README list omits trio, while COMPANIONS/core.md include it; the test only asserts names appear in core.md.

**Impact** Plugin guidance and installation commands will continue to drift despite the attempted fix.

**Correction** Make one machine-readable companion manifest authoritative and derive onboarding output and documentation from it; avoid separately maintained plugin lists in core.md and README.md.

#### Legacy-hook detector still labels arbitrary user hooks as old leftovers

**Where** `hooks/onboarding.py:76` · **Lens** simplifier · **Id** `f71a7c7e`

**Evidence** Every command containing ~/.claude/hooks/ increments dead without extracting its script or checking whether it is one of the known superseded scripts. _compose then presents these entries under "Leftovers from the old symlink install."

**Impact** A user's legitimate hook configuration is misleadingly presented as obsolete and may be removed through /unlink-legacy.

**Correction** Extract and resolve each referenced script; report only absent targets or the explicitly named removed scripts, and leave other ~/.claude/hooks entries unmentioned.

#### Trio onboarding command lacks the required marketplace URL

**Where** `hooks/onboarding.py:108` · **Lens** consistency · **Id** `de3cb149`

**Evidence** onboarding.py:108 emits `/plugin install trio@trio-cc`; lines 109-110 only instruct `/plugin marketplace add <url>`. README.md:168 provides the actual required source, `karakijihad/trio-cc`.

**Impact** A first-run user missing trio receives an install sequence that cannot add its marketplace as written, so the advertised companion installation fails.

**Correction** Store the marketplace source alongside the marketplace name and emit `/plugin marketplace add karakijihad/trio-cc` before the trio install command.

### Minor

#### No-Python fallback test still requires Python

**Where** `hooks/test-hooks.sh:33` · **Lens** auditor · **Id** `9db1285c`

**Evidence** The fallback case replaces the temporary py.sh at lines 42-45, but json_ok validates its output through the repository's bash py.sh at line 33. A machine with no working Python cannot run the assertion claimed to verify that fallback.

**Impact** The suite can report a fallback test only in environments that retain Python; it does not verify the advertised no-Python runtime path end-to-end.

**Correction** Validate the fallback JSON with jq when available and add a shell-only assertion for the no-Python/no-jq reduced-output branch, or document that this test requires Python.

#### Last-resort fallback still maintains a second policy copy

**Where** `hooks/session-start.sh:29` · **Lens** simplifier · **Id** `9fa3f43c`

**Evidence** core.md is the primary policy, but the no-Python/no-jq branch embeds a separate 651-character policy string with overlapping rules.

**Impact** Policy changes still require synchronized edits and behavior differs depending on local tooling.

**Correction** Use a single minimal policy data file that both fallback paths emit, with the full core as an optional enhancement.

#### Sanitizer test duplicates the implementation

**Where** `hooks/test-hooks.sh:77` · **Lens** simplifier · **Id** `013fe0aa`

**Evidence** The test independently repeats notify.sh's tr/cut sanitization pipeline instead of exercising notify.sh's backend command construction.

**Impact** The test can remain green when notify.sh's sanitizer changes or is removed, providing false confidence.

**Correction** Stub osascript or powershell.exe on PATH and assert the actual arguments emitted by notify.sh.

#### Project documentation still identifies the old resident-core source

**Where** `CLAUDE.md:4` · **Lens** consistency · **Id** `093f8c7e`

**Evidence** CLAUDE.md:4 says the shipped config lives in `hooks/session-start.py`, while CLAUDE.md:13-18 and hooks/session-start.py:25-29 establish `hooks/core.md` as the policy source and session-start.py as its wrapper.

**Impact** Readers may edit the wrapper expecting to change resident policy, recreating the duplicated-source problem the migration was intended to remove.

**Correction** Change the reference to `hooks/core.md` (and optionally mention session-start.py only as the wrapper).

#### Feedback protocol directs general behavior edits to the former core location

**Where** `skills/feedback-protocol/SKILL.md:36` · **Lens** consistency · **Id** `695388ce`

**Evidence** skills/feedback-protocol/SKILL.md:36 directs general-behavior corrections to `hooks/session-start.py`; the current policy is loaded from hooks/core.md by session-start.py:29-52.

**Impact** Applying the protocol as written can put behavior rules in code rather than the resident policy file, causing stale or ineffective edits.

**Correction** Replace `hooks/session-start.py` with `hooks/core.md` in the rule-location table.

## Verification Notes

All enabled lenses completed and returned a parseable findings block.

## Overall Assessment

17 finding(s) across 5 lens(es).
