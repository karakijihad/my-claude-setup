// Status line — three lines.
//
//   Opus 5 (1M context) · high | Session $15.75 - 1h 29m
//   Context 277k/1.0M (28%) | Cache Hit 99% | mem 27.1/31.8G | Skill artifact-design
//   branch main | +1523/-393
//
// Line 1 is identity and what the session has spent. Line 2 is what the session
// and the machine are carrying right now. Line 3 is the repo.
//
// Claude Code pipes a JSON snapshot of session state to stdin on every status
// refresh and prints whatever this writes to stdout. That puts it on the render
// path: it runs far more often than a hook does, and any cost here is paid as
// visible terminal lag rather than as a pause between turns.
//
// Almost everything shown is read straight from that payload, which is the
// authority — it carries the model, the effort level, the real context-window
// size, a usage breakdown and a cost. Deriving any of those from the transcript
// instead would be guessing at a number the harness already knows. The one
// exception is the active skill, which the payload does not report, so it is
// recovered by scanning the transcript for the newest Skill invocation.
//
// Two rules keep it near node's own startup cost, which is the floor:
//
//   - No dependencies, and no subprocess. The branch comes from reading
//     .git/HEAD as a text file; shelling out to `git` costs a process spawn —
//     90-200ms on Windows — for a value sitting in a 41-byte file.
//   - The transcript scan looks only for Skill invocations, and parses a line
//     only once the cheap substring test has already matched.
//
// Every failure path degrades to a shorter line and exits 0. A status line that
// throws leaves the user staring at a blank bar with nothing to debug from.
//
// To see exactly what the harness sent: `touch ~/.claude/statusline-debug`, and
// the next render writes the raw payload to ~/.claude/statusline-payload.json.
// The payload's shape is the harness's to change, which is why every field read
// below is optional and every widget disappears rather than breaking.

import {
  readFileSync, writeFileSync, openSync, fstatSync, readSync, closeSync,
} from "node:fs";
import { execFileSync } from "node:child_process";
import { freemem, totalmem } from "node:os";
import { join, dirname } from "node:path";

// Opt-in: dirty-file count on line 3. Costs one `git status` spawn (~120ms),
// the one thing here that reintroduces the cost this file exists to avoid.
const WANT_CHANGES = process.env.STATUSLINE_GIT_CHANGES === "1";

// The active skill may have been invoked many turns ago, so this reads the
// whole transcript rather than a tail. Capped so a very long session degrades
// to "since the cap" instead of reading tens of MB on every render.
const MAX_SCAN = 8 * 1024 * 1024;

const k = (n) =>
  n >= 1_000_000 ? `${(n / 1e6).toFixed(1)}M` : n >= 1000 ? `${Math.round(n / 1000)}k` : String(n);

// ── git ─────────────────────────────────────────────────────────────────────

function gitInfo(start) {
  for (let d = start; d; ) {
    try {
      const p = join(d, ".git");
      let head;
      try {
        head = readFileSync(join(p, "HEAD"), "utf8");
      } catch {
        // A worktree or submodule writes `gitdir: <path>` into a .git *file*.
        const link = readFileSync(p, "utf8").match(/gitdir:\s*(.+)/);
        if (!link) throw new Error("not a gitdir");
        head = readFileSync(join(link[1].trim(), "HEAD"), "utf8");
      }
      const m = head.match(/ref:\s*refs\/heads\/(.+)/);
      return { dir: d, branch: m ? m[1].trim() : head.trim().slice(0, 7) };
    } catch {
      const up = dirname(d);
      if (up === d) return null;
      d = up;
    }
  }
  return null;
}

function dirtyCount(dir) {
  try {
    return execFileSync("git", ["status", "--porcelain"], {
      cwd: dir, encoding: "utf8", timeout: 2000,
      windowsHide: true, stdio: ["ignore", "pipe", "ignore"],
    }).split("\n").filter((l) => l.trim()).length;
  } catch {
    return null; // no git on PATH, or a repo too large to answer in time
  }
}

// ── the active skill ────────────────────────────────────────────────────────

// Returns the most recently invoked skill on the main thread, or null.
//
// This is the last skill *invoked*, not one known to still be running: nothing
// in the transcript marks a skill as finished, so the name is sticky until
// another is invoked. Sidechain records are skipped — a sub-agent's skill is
// not what is steering the main thread.
function activeSkill(path) {
  let fd, found = null;
  try {
    fd = openSync(path, "r");
    const size = fstatSync(fd).size;
    const len = Math.min(MAX_SCAN, size);
    const buf = Buffer.alloc(len);
    readSync(fd, buf, 0, len, size - len);

    for (const line of buf.toString("utf8").split("\n")) {
      if (!line.includes('"Skill"')) continue; // cheap test before any parse
      let o;
      try {
        o = JSON.parse(line);
      } catch {
        continue; // truncated first line when reading from an offset
      }
      if (o.isSidechain || !Array.isArray(o?.message?.content)) continue;
      for (const b of o.message.content) {
        if (b?.type === "tool_use" && b.name === "Skill" && b.input?.skill) found = b.input.skill;
      }
    }
  } catch {
    // No transcript yet on the first render of a fresh session.
  } finally {
    if (fd !== undefined) try { closeSync(fd); } catch {}
  }
  return found;
}

// ── render ──────────────────────────────────────────────────────────────────

let raw = "";
process.stdin.on("error", () => process.exit(0));
process.stdin.on("data", (c) => (raw += c));
process.stdin.on("end", () => {
  try {
    const home = process.env.USERPROFILE ?? process.env.HOME ?? "";
    readFileSync(join(home, ".claude", "statusline-debug"));
    writeFileSync(join(home, ".claude", "statusline-payload.json"), raw);
  } catch {
    // no flag, or unwritable — never let a debug aid break the status line
  }

  let j = {};
  try {
    j = JSON.parse(raw);
  } catch {
    // fall through — every field below is optional
  }

  // 256-colour, not 24-bit: every terminal that renders a status line supports
  // it, and the palette is chosen to stay legible on both a light and a dark
  // terminal ground rather than to look best on one.
  //
  // Colour is a signal. Context, cache and memory are scaled — green while
  // there is headroom, amber when it is worth noticing, red when it needs
  // action — so the bar reads at a glance without parsing a number. Labels take
  // a receding slate so they frame the values instead of competing with them,
  // and identities (model, skill, branch) get a fixed hue each.
  const c = (n, t) => `\x1b[38;5;${n}m${t}\x1b[0m`;
  const GOOD = 114, WARN = 221, BAD = 203;
  const MODEL = 81, SKILL = 140, BRANCH = 79, MONEY = 180, TIME = 109, LABEL = 66, RULE = 240;
  // Ascending: more is worse (context fill, memory pressure).
  const up = (v, warn, bad) => (v >= bad ? BAD : v >= warn ? WARN : GOOD);
  // Descending: less is worse (cache hit rate).
  const down = (v, warn, bad) => (v <= bad ? BAD : v <= warn ? WARN : GOOD);
  const lab = (t) => c(LABEL, t);
  const sep = ` ${c(RULE, "|")} `;

  const cwd = j.workspace?.current_dir ?? j.cwd;
  const win = j.context_window;
  const cur = win?.current_usage;

  // ── line 1: identity, and what the session has spent ────────────────────
  const l1 = [];
  const model = j.model?.display_name;
  // Effort is set in settings, paid on every message, and surfaced nowhere else
  // in the interface — which is why it sits beside the model rather than in a
  // config file nobody opens mid-task.
  const effort = j.effort?.level;
  if (model || effort) {
    const tone = { low: GOOD, medium: TIME, high: WARN, xhigh: BAD, max: BAD };
    l1.push(
      [model && c(MODEL, model), effort && c(tone[effort] ?? TIME, effort)]
        .filter(Boolean).join(c(RULE, " · ")),
    );
  }
  const usd = j.cost?.total_cost_usd;
  const ms = j.cost?.total_duration_ms; // wall clock; total_api_duration_ms is the API share
  const spent = [];
  if (typeof usd === "number") spent.push(c(MONEY, `$${usd.toFixed(2)}`));
  if (typeof ms === "number") {
    const min = Math.floor(ms / 60000);
    spent.push(c(TIME, min >= 60 ? `${Math.floor(min / 60)}h ${min % 60}m` : `${min}m`));
  }
  if (spent.length) l1.push(`${lab("Session")} ${spent.join(c(RULE, " - "))}`);

  // ── line 2: what the session and the machine are carrying ───────────────
  const l2 = [];
  if (win) {
    // used_percentage is the harness's own figure — it knows what it packed
    // into the request, including anything this script cannot see.
    const pct = win.used_percentage ?? 0;
    const used = win.total_input_tokens ?? 0;
    const size = win.context_window_size ?? 0;
    l2.push(`${lab("Context")} ${c(up(pct, 60, 85), `${k(used)}/${k(size)}`)} ${c(RULE, `(${pct}%)`)}`);
  }
  if (cur) {
    // Floor, never round. A steady session sits around 99.6% — the newest turn
    // is cache_creation and everything before it is cache_read — and rounding
    // turns that into "100%", claiming a perfect hit that did not happen.
    const prompt =
      (cur.input_tokens ?? 0) + (cur.cache_read_input_tokens ?? 0) + (cur.cache_creation_input_tokens ?? 0);
    if (prompt > 0 && cur.cache_read_input_tokens) {
      const hit = Math.floor((cur.cache_read_input_tokens / prompt) * 100);
      l2.push(`${lab("Cache Hit")} ${c(down(hit, 90, 70), `${hit}%`)}`);
    }
  }
  // Used-of-total, because free-of-total reads backwards next to every other
  // ratio on this line, all of which fill up rather than drain.
  //
  // One caveat this cannot express: node only knows *free*, so "used" here is
  // total - free. On Windows that counts the standby cache — memory the OS
  // hands back on demand — as used, so this reads a few GB higher than Task
  // Manager's figure. Directionally right, deliberately pessimistic, and the
  // thresholds are set with that in mind rather than against a truer number
  // node has no way to obtain.
  const gb = (b) => (b / 1024 ** 3).toFixed(1);
  const useM = totalmem() - freemem();
  l2.push(`${lab("mem")} ${c(up((useM / totalmem()) * 100, 80, 92), `${gb(useM)}/${gb(totalmem())}G`)}`);
  const skill = j.transcript_path ? activeSkill(j.transcript_path) : null;
  if (skill) l2.push(`${lab("Skill")} ${c(SKILL, skill)}`);

  // ── line 3: the repo ────────────────────────────────────────────────────
  const l3 = [];
  const git = cwd ? gitInfo(cwd) : null;
  if (git) {
    l3.push(`${lab("branch")} ${c(BRANCH, git.branch)}`);
    // Labelled "edits", not shown as a bare +/-, because this is NOT the
    // working-tree diff it would otherwise be read as sitting next to a branch
    // name. It is every line this session has written, cumulative and from the
    // payload — commits included, so it does not shrink when work lands. The
    // real diff would cost a `git` spawn on the render path.
    const add = j.cost?.total_lines_added, del = j.cost?.total_lines_removed;
    if (typeof add === "number" || typeof del === "number") {
      l3.push(`${lab("edits")} ${c(GOOD, `+${add ?? 0}`)}${c(RULE, "/")}${c(BAD, `-${del ?? 0}`)}`);
    }
    if (WANT_CHANGES) {
      const n = dirtyCount(git.dir);
      if (n !== null) l3.push(n ? c(WARN, `${n} changed`) : c(GOOD, "clean"));
    }
  }

  process.stdout.write(
    [l1, l2, l3].filter((l) => l.length).map((l) => l.join(sep)).join("\n"),
  );
});
