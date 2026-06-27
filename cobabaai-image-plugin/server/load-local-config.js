import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

function codexHome() {
  return process.env.CODEX_HOME?.trim() || join(homedir(), ".codex");
}

export function localConfigPath() {
  return join(codexHome(), "cobabaai-image.env");
}

function parseEnvLine(line) {
  const trimmed = line.trim();
  if (!trimmed || trimmed.startsWith("#")) {
    return null;
  }

  const eq = trimmed.indexOf("=");
  if (eq <= 0) {
    return null;
  }

  const key = trimmed.slice(0, eq).trim();
  let value = trimmed.slice(eq + 1).trim();
  if (
    (value.startsWith('"') && value.endsWith('"')) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    value = value.slice(1, -1);
  }

  return { key, value };
}

export function loadLocalConfig() {
  const path = localConfigPath();
  if (!existsSync(path)) {
    return path;
  }

  const content = readFileSync(path, "utf8");
  for (const line of content.split(/\r?\n/)) {
    const parsed = parseEnvLine(line);
    if (!parsed || process.env[parsed.key]) {
      continue;
    }
    process.env[parsed.key] = parsed.value;
  }

  return path;
}
