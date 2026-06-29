import { buildLocalImageMarkdown, saveOriginalPng, toCodexPath } from "../server/save-image.js";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const existing = join(
  process.env.USERPROFILE,
  ".codex",
  "cobabaai-images",
  "unit_test.png",
);
const buffer = readFileSync(existing);
const saved = saveOriginalPng(buffer, "path_test");
const md = buildLocalImageMarkdown(saved, "test");
console.log("path:", toCodexPath(saved));
console.log("markdown:", md);
if (!md.includes("C:/") || !md.endsWith(".png)")) {
  console.error("FAIL");
  process.exit(1);
}
console.log("PASS");
