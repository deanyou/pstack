import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";

test("mirror sync copies nested runtime scripts and preserves mirror-owned files", () => {
  const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "pstack-sync-"));
  const source = path.join(tmp, "source");
  const target = path.join(tmp, "target");
  const put = (base, file, text) => {
    const dest = path.join(base, file);
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    fs.writeFileSync(dest, text);
  };
  try {
    put(source, "scripts/upstream-root", "excluded");
    put(source, "skills/statechart/scripts/statechart", "runtime");
    put(target, "scripts/mirror-helper", "preserved");
    put(target, "skills/statechart/examples/runtime-lookup/model", "proof");
    execFileSync("rsync", [
      "-a", "--delete", `--exclude-from=${path.join(root, "mirror-paths.txt")}`,
      `${source}/`, `${target}/`,
    ]);
    assert.equal(fs.readFileSync(path.join(target, "skills/statechart/scripts/statechart"), "utf8"), "runtime");
    assert.equal(fs.readFileSync(path.join(target, "scripts/mirror-helper"), "utf8"), "preserved");
    assert.equal(fs.readFileSync(path.join(target, "skills/statechart/examples/runtime-lookup/model"), "utf8"), "proof");
    assert.equal(fs.existsSync(path.join(target, "scripts/upstream-root")), false);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});
