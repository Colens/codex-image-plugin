#!/usr/bin/env node
import { loadLocalConfig } from "./load-local-config.js";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import {
  generateImage,
  listSupportedModels,
  pollImageTask,
} from "./cobabaai-client.js";
import { MODEL_OPTIONS } from "./model-config.js";

loadLocalConfig();

const server = new McpServer({
  name: "cobabaai-image",
  version: "0.1.1",
});

server.tool(
  "generate_image",
  "使用 CobabaAi 异步生图接口生成图片。提交任务并自动轮询，返回图片 URL。",
  {
    prompt: z.string().min(1).describe("图片描述 prompt"),
    model: z
      .enum(MODEL_OPTIONS)
      .optional()
      .describe("生图模型，默认 gpt-image-2"),
    aspectRatio: z
      .string()
      .optional()
      .describe("宽高比或尺寸，如 auto、1:1、1024x1024"),
    variants: z.number().int().min(1).max(4).optional().describe("生成张数，默认 1"),
    referenceUrls: z
      .array(z.string())
      .optional()
      .describe("参考图 URL 列表，用于图生图"),
    imageSize: z
      .enum(["1K", "2K", "4K"])
      .optional()
      .describe("部分 nano-banana 模型支持的清晰度"),
  },
  async (args) => {
    const result = await generateImage(args);
    return {
      content: [
        {
          type: "text",
          text: [
            "CobabaAi 生图完成。",
            `模型: ${result.model}`,
            `任务 ID: ${result.taskId}`,
            `图片 URL: ${result.imageUrl}`,
            "",
            "请在回复中用 Markdown 图片语法展示给用户，例如：",
            `![${result.prompt.slice(0, 80)}](${result.imageUrl})`,
          ].join("\n"),
        },
      ],
      structuredContent: result,
    };
  },
);

server.tool(
  "poll_image_task",
  "查询 CobabaAi 异步生图任务状态（通常无需单独调用，generate_image 已自动轮询）。",
  {
    taskId: z.string().min(1).describe("提交生图时返回的任务 ID"),
  },
  async ({ taskId }) => {
    const result = await pollImageTask(taskId);
    return {
      content: [
        {
          type: "text",
          text: `任务 ${result.taskId} 已完成。\n图片 URL: ${result.imageUrl}`,
        },
      ],
      structuredContent: result,
    };
  },
);

server.tool(
  "list_image_models",
  "列出 CobabaAi 支持的生图模型。",
  {},
  async () => {
    const models = listSupportedModels();
    return {
      content: [
        {
          type: "text",
          text: models.map((item) => `- ${item.model}`).join("\n"),
        },
      ],
      structuredContent: { models },
    };
  },
);

const transport = new StdioServerTransport();
await server.connect(transport);
