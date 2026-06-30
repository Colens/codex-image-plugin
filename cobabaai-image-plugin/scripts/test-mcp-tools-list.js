import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const pluginDir = join(__dirname, "..");
const nodeExe = process.execPath;
const serverJs = join(pluginDir, "server", "index.js");

const client = new Client({ name: "doctor", version: "1.0.0" });
const transport = new StdioClientTransport({
  command: nodeExe,
  args: [serverJs],
  cwd: pluginDir,
  env: {
    ...process.env,
    COBABAAI_API_KEY: process.env.COBABAAI_API_KEY || "sk-test-placeholder",
  },
});

try {
  await client.connect(transport);
  const { tools } = await client.listTools();
  const names = tools.map((t) => t.name).sort();
  const ok = names.length === 1 && names[0] === "cobabaai_draw";
  if (ok) {
    console.log("tools:cobabaai_draw");
    process.exit(0);
  }
  console.error("unexpected tools:", names.join(","));
  process.exit(1);
} catch (error) {
  console.error("mcp tools list failed:", error.message);
  process.exit(1);
} finally {
  await client.close().catch(() => {});
}
