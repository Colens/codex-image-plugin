import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

function codexHome() {
  return process.env.CODEX_HOME?.trim() || join(homedir(), ".codex");
}

export function imagesDir() {
  return join(codexHome(), "cobabaai-images");
}

/** Windows Codex 聊天可渲染：![alt](C:/path/file.png)，须正斜杠 */
export function toCodexPath(filePath) {
  return filePath.replace(/\\/g, "/");
}

export function saveOriginalPng(buffer, taskId) {
  const dir = imagesDir();
  mkdirSync(dir, { recursive: true });
  const safeId = String(taskId).replace(/[^\w-]/g, "_");
  const filePath = join(dir, `${safeId}.png`);
  writeFileSync(filePath, buffer);
  return filePath;
}

export function buildLocalImageMarkdown(filePath, alt) {
  const safeAlt = String(alt).slice(0, 80).replace(/[\[\]()]/g, "");
  return `![${safeAlt}](${toCodexPath(filePath)})`;
}
