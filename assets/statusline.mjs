// Status line, two lanes.
//
//   Opus 5 · high | 170k/1000k (17%) | cached 169k (99%) | main
//   sub · 12 calls | 340k in | 18k out | $1.23 session
//
// Line 1 is the main thread, and its context figure is a *point in time*: what
// the last request actually carried. Line 2 is the sub-agent lane, and its
// figures are *cumulative*: what every sub-agent has consumed so far. The two
// are different measures on purpose — you steer the main thread by how full it
// is right now, and you judge delegation by what it has cost in total.
//
// Claude Code pipes a JSON snapshot of session state to stdin on every status
// refresh and prints whatever this writes to stdout. That puts it on the render
// path: it runs far more often than a hook does, and any cost here is paid as
// visible terminal lag rather than as a pause between turns. Everything below
// is shaped by that single constraint.
//
// Three rules keep it near node's own startup cost, which is the floor:
//
//   - No dependencies. Nothing to resolve, nothing to load.
//   - No subprocesses. The branch comes from reading .git/HEAD as a text file;
//     shelling out to `git` would cost a process spawn — 90-200ms on Windows —
//     for a value sitting in a 41-byte file.
//   - Parse only what is needed. The transcript is scanned once, and a line is
//     handed to JSON.parse only if it contains a usage block at all.
//
// Every failure path degrades to a shorter line and exits 0. A status line that
// throws leaves the user staring at a blank bar with nothing to debug from.

import { readFileSync, openSync, fstatSync, readSync, closeSync } from "node:fs";
import { join, dirname } from "node:path";

// Sub-agent totals are cumulative, so they need the whole file, not a tail.
// Transcripts do reach tens of MB in a long session, so this caps the read and
// falls back to the newest slice — the main-thread figures stay exact either
// way, and the sub-agent totals become "since the cap", which is reported.
const MAX_SCAN = 8 * 1024 * 1024;

// Context windows are a property of the model, and getting this wrong is worse
// than omitting it — a percentage against the wrong denominator reads as
// authoritative. Anything unrecognised falls back to the common 200k.
function contextLimit(id = "") {
  return id.includes("[1m]") || id.includes("1m") ? 1_000_000 : 200_000;
}

function branch(dir) {
  // Walk up for .git so a subdirectory of the repo still reports the branch.
  // A worktree or submodule writes `gitdir: <path>` into a .git *file*; that
  // resolves to a directory whose HEAD is the one we want.
  for (let d = dir; d; ) {
    try {
      const p = join(d, ".git");
      let head;
      try {
        head = readFileSync(join(p, "HEAD"), "utf8");
      } catch {
        const link = readFileSync(p, "utf8").match(/gitdir:\s*(.+)/);
        if (!link) throw new Error("not a gitdir");
        head = readFileSync(join(link[1].trim(), "HEAD"), "utf8");
      }
      const m = head.match(/ref:\s*refs\/heads\/(.+)/);
      return m ? m[1].trim() : head.trim().slice(0, 7); // detached: show the SHA
    } catch {
      const up = dirname(d);
      if (up === d) return null;
      d = up;
    }
  }
  return null;
}

// The prompt is what is in the window: input + both cache halves. Output is
// deliberately excluded — those tokens came *out* of the model and are not
// occupying context, so counting them overstates a figure labelled "context".
const promptTokens = (u) =>
  (u.input_tokens ?? 0) +
  (u.cache_read_input_tokens ?? 0) +
  (u.cache_creation_input_tokens ?? 0);

function scan(path) {
  const out = {
    main: null,
    effort: null,
    sub: { calls: 0, input: 0, output: 0 },
    partial: false,
  };
  let fd;
  try {
    fd = openSync(path, "r");
    const size = fstatSync(fd).size;
    const len = Math.min(MAX_SCAN, size);
    out.partial = len < size;
    const buf = Buffer.alloc(len);
    readSync(fd, buf, 0, len, size - len);

    for (const line of buf.toString("utf8").split("\n")) {
      if (!line.includes('"usage"')) continue;
      let o;
      try {
        o = JSON.parse(line);
      } catch {
        continue; // truncated first line when reading from an offset
      }
      const u = o?.message?.usage;
      if (!u) continue;

      // Sidechain records are sub-agent turns. Without this split the newest
      // record often belongs to a sub-agent, whose context is unrelated to the
      // main thread's — the status line would then report someone else's window
      // as yours, and be wrong in exactly the moments delegation is busiest.
      if (o.isSidechain) {
        out.sub.calls++;
        out.sub.input += promptTokens(u);
        out.sub.output += u.output_tokens ?? 0;
      } else {
        out.main = u;
        out.effort = o.effort ?? out.effort;
      }
    }
  } catch {
    // No transcript yet on the first render of a fresh session.
  } finally {
    if (fd !== undefined) try { closeSync(fd); } catch {}
  }
  return out;
}

const k = (n) => (n >= 1000 ? `${Math.round(n / 1000)}k` : String(n));

let raw = "";
process.stdin.on("error", () => process.exit(0));
process.stdin.on("data", (c) => (raw += c));
process.stdin.on("end", () => {
  let j = {};
  try {
    j = JSON.parse(raw);
  } catch {
    // fall through — every field below is optional
  }

  const C = { cyan: "\x1b[36m", dim: "\x1b[2m", off: "\x1b[0m" };
  const sep = ` ${C.dim}|${C.off} `;
  const s = j.transcript_path ? scan(j.transcript_path) : null;

  // ── line 1: the main thread ──────────────────────────────────────────────
  //
  // No model name here. Claude Code prints its own model and mode indicators
  // directly above this, and a status line's job is to add what the harness
  // does not already show. Effort is exactly that: it is set in settings.json,
  // it changes cost and latency on every message, and nothing else surfaces it.
  const l1 = [];
  if (s?.effort) l1.push(`${C.cyan}${s.effort}${C.off}`);
  if (s?.main) {
    const used = promptTokens(s.main);
    const limit = contextLimit(j.model?.id ?? "");
    l1.push(`${k(used)}/${k(limit)} ${C.dim}(${Math.round((used / limit) * 100)}%)${C.off}`);

    // Cache hit ratio, not just the raw number: it answers "is prompt caching
    // working", which a token count alone cannot. A sudden drop here is the
    // visible symptom of a cache break.
    //
    // Floor, never round. A steady session sits around 99.6% — the newest turn
    // is cache_creation and everything before it is cache_read — and rounding
    // turns that into "100%", which claims a perfect hit that did not happen.
    // Flooring means 100% appears only when the miss is genuinely zero.
    const cached = s.main.cache_read_input_tokens ?? 0;
    if (cached) {
      l1.push(`${C.dim}cached ${k(cached)} (${Math.floor((cached / used) * 100)}%)${C.off}`);
    }
  }
  const dir = j.workspace?.current_dir ?? j.cwd;
  const b = dir ? branch(dir) : null;
  if (b) l1.push(`${C.dim}${b}${C.off}`);

  // ── line 2: the sub-agent lane, cumulative ───────────────────────────────
  const l2 = [];
  if (s?.sub.calls) {
    l2.push(`${C.dim}sub · ${s.sub.calls} call${s.sub.calls === 1 ? "" : "s"}${C.off}`);
    l2.push(`${C.dim}${k(s.sub.input)} in${C.off}`);
    l2.push(`${C.dim}${k(s.sub.output)} out${C.off}`);
    if (s.partial) l2.push(`${C.dim}(capped)${C.off}`);
  } else {
    l2.push(`${C.dim}sub · idle${C.off}`);
  }

  // ── line 3: what the session has spent ───────────────────────────────────
  //
  // Cost comes from the payload rather than being derived from tokens, and it
  // covers the WHOLE session, main thread included — hence its own line and the
  // "all lanes" label. On the sub-agent line, unqualified, it read as the
  // sub-agents' bill. Splitting it per lane is not possible from here: Claude
  // Code reports one number, and deriving two would need a hardcoded per-model
  // price table, which goes stale silently and then reports confident, wrong
  // money.
  const l3 = [];
  const usd = j.cost?.total_cost_usd;
  if (typeof usd === "number") l3.push(`$${usd.toFixed(2)} ${C.dim}all lanes${C.off}`);
  const ms = j.cost?.total_duration_ms;
  if (typeof ms === "number") {
    const min = Math.floor(ms / 60000);
    l3.push(`${C.dim}${min >= 60 ? `${Math.floor(min / 60)}h ${min % 60}m` : `${min}m`}${C.off}`);
  }

  process.stdout.write([l1, l2, l3].filter((l) => l.length).map((l) => l.join(sep)).join("\n"));
});
