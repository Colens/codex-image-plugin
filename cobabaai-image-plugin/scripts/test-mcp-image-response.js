/**
 * 验证 MCP 返回：text 含 data-URI Markdown，无 structuredContent
 */
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { join } from "node:path";

const pluginDir = process.cwd();
const nodeExe =
  process.env.NODE_EXE ||
  join(process.env.USERPROFILE || "", ".codex", "packages", "node", "node.exe");

const transport = new StdioClientTransport({
  command: nodeExe,
  args: ["server/index.js"],
  cwd: pluginDir,
  env: process.env,
});

const client = new Client({ name: "test", version: "1.0.0" });
await client.connect(transport);

const result = await client.callTool({
  name: "generate_image",
  arguments: {
    prompt: "一只猫在月球喝酒，简洁插画",
    model: "gpt-image-2",
    resolution: "1280x1280",
  },
});

const text = result.content?.find((b) => b.type === "text")?.text ?? "";
const mdLine = text.split("\n").find((l) => l.startsWith("!["));

console.log("structuredContent:", result.structuredContent ?? "(none)");
console.log("has data-uri markdown:", mdLine?.startsWith("![") && mdLine.includes("data:image/jpeg;base64,"));
console.log("markdown length:", mdLine?.length ?? 0);
console.log("local_file line:", text.includes("local_file="));

if (result.structuredContent) {
  console.error("FAIL: structuredContent present");
  process.exit(1);
}
if (!mdLine?.includes("data:image/jpeg;base64,")) {
  console.error("FAIL: missing data-uri markdown");
  process.exit(1);
}
console.log("PASS");
await client.close();
