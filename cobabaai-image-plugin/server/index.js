#!/usr/bin/env node
import { loadLocalConfig } from "./load-local-config.js";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { MODEL_OPTIONS, MODELS_HELP } from "./model-config.js";
import { handleDraw } from "./draw-handler.js";

loadLocalConfig();

if (process.env.COBABAAI_MCP_DEBUG === "1") {
  const keyConfigured = !!process.env.COBABAAI_API_KEY?.trim();
  console.error(`[cobabaai-image] ready api_key=${keyConfigured ? "ok" : "MISSING"}`);
}

const MCP_INSTRUCTIONS =
  "CobabaAi唯一生图入口=本工具cobabaai_draw。禁止读SKILL/README/搜网页/读.env/列MCP工具。收到@生图或上传图片→立刻调用本工具，零前置文字。有附件→referenceImagePaths。成功后只贴返回的Markdown图行。";

const refPathsSchema = z
  .array(z.string().min(1))
  .optional()
  .describe("垫图/图生图：用户附件或 cobabaai-images 的 C:/ 绝对路径");

const refUrlsSchema = z
  .array(z.string().min(1))
  .optional()
  .describe("垫图 URL，可选");

const batchItemSchema = z.object({
  prompt: z.string().min(1),
  referenceImagePaths: refPathsSchema,
  referenceUrls: refUrlsSchema,
});

const server = new McpServer({
  name: "cobabaai-image",
  version: "0.3.3",
  instructions: MCP_INSTRUCTIONS,
});

server.tool(
  "cobabaai_draw",
  `${MCP_INSTRUCTIONS} 单张:prompt+referenceImagePaths。批量:items或prompts。模型:${MODELS_HELP}`,
  {
    prompt: z
      .string()
      .optional()
      .describe("单张画面描述，如「两只边牧分别坐在沙发左右」"),
    referenceImagePaths: refPathsSchema,
    referenceUrls: refUrlsSchema,
    model: z.enum(MODEL_OPTIONS).optional(),
    resolution: z.string().optional(),
    aspectRatio: z.string().optional(),
    variants: z.number().int().min(1).max(4).optional(),
    items: z.array(batchItemSchema).min(2).optional(),
    prompts: z.array(z.string().min(1)).min(2).optional(),
  },
  async (args) => {
    const text = await handleDraw(args);
    return { content: [{ type: "text", text }] };
  },
);

const transport = new StdioServerTransport();
await server.connect(transport);
