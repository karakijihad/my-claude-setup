// Stable-path launcher for the status line.
//
// `/setup` copies this one file to ~/.claude/statusline.mjs and points
// settings.json at *that* path, which never changes. It then resolves the
// installed plugin at run time and hands off to the real script.
//
// The indirection exists because the plugin's own directory is version-pinned
// — .../my-claude-setup/<version>/assets/statusline.mjs — so a settings.json
// written against one release stops matching the next. That failure is not
// loud: Claude Code keeps every previously installed version in the cache, so
// the stale path still resolves and still runs. The bar goes on rendering
// happily from a release you stopped using months ago, and nothing anywhere
// says so. Observed in the wild before this file existed: settings pointing at
// 1.7.0 with 1.8.0 installed and ten versions on disk.
//
// installed_plugins.json is the authority Claude Code itself uses, so this
// reads that rather than sorting directory names — a lexical sort puts 1.10.0
// before 1.9.0, and a semver parser here would be more code than the thing it
// launches.

import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

const home = process.env.USERPROFILE ?? process.env.HOME ?? "";
const PLUGIN = "my-claude-setup";

function resolveTarget() {
  const manifest = join(home, ".claude", "plugins", "installed_plugins.json");
  const { plugins } = JSON.parse(readFileSync(manifest, "utf8"));
  const key = Object.keys(plugins).find((k) => k.split("@")[0] === PLUGIN);
  if (!key) throw new Error(`${PLUGIN} is not installed`);

  // Entries are per scope; take the first that still exists on disk, since an
  // uninstalled scope can linger in the manifest.
  for (const entry of plugins[key]) {
    const target = join(entry.installPath, "assets", "statusline.mjs");
    if (existsSync(target)) return target;
  }
  throw new Error("no installed copy carries assets/statusline.mjs");
}

try {
  // Dynamic import rather than spawning node twice: the real script reads the
  // same stdin this process was given, and the render path cannot afford a
  // second process for what is a path lookup.
  await import(pathToFileURL(resolveTarget()).href);
} catch (err) {
  // Print nothing and leave cleanly. A status line is not worth a stack trace
  // in the one part of the interface that has no room for one, and a blank bar
  // with a working session beats a broken session with a bar.
  if (process.env.STATUSLINE_DEBUG) process.stderr.write(String(err) + "\n");
  process.exit(0);
}
