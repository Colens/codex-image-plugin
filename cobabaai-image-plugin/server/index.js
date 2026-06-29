#!/usr/bin/env node
import { loadLocalConfig } from "./load-local-config.js";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import {
  generateImage,
  listSupportedModels,
  fetchImageContent,
} from "./cobabaai-client.js";
import { MODEL_OPTIONS, MODELS_HELP } from "./model-config.js";
import { buildLocalImageMarkdown, saveOriginalPng } from "./save-image.js";
import { runBatchAndBuildMarkdown } from "./batch-images.js";

loadLocalConfig();

const keyConfigured = !!process.env.COBABAAI_API_KEY?.trim();
console.error(`[cobabaai-image] ready api_key=${keyConfigured ? "ok" : "MISSING"}`);

const server = new McpServer({
  name: "cobabaai-image",
  version: "0.2.5",
});

server.tool(
  "generate_image",
  `单张生图。返回一行 ![...](C:/...png)。模型:${MODELS_HELP}`,
  {
    prompt: z.string().min(1),
    model: z.enum(MODEL_OPTIONS).optional(),
    resolution: z.string().optional(),
    aspectRatio: z.string().optional(),
    variants: z.number().int().min(1).max(4).optional().describe("同 prompt 出多张，最多4"),
  },
  async (args) => {
    const result = await generateImage(args);
    const urls = result.imageUrls?.length
      ? result.imageUrls
      : [result.imageUrl];
    const lines = [];
    for (let i = 0; i < urls.length; i += 1) {
      const image = await fetchImageContent(urls[i]);
      const savedPath = saveOriginalPng(
        image.buffer,
        urls.length > 1 ? `${result.taskId}_${i + 1}` : result.taskId,
      );
      lines.push(
        buildLocalImageMarkdown(
          savedPath,
          urls.length > 1 ? `${result.prompt} ${i + 1}` : result.prompt,
        ),
      );
    }
    return { content: [{ type: "text", text: lines.join("\n") }] };
  },
);

server.tool(
  "generate_images_batch",
  `多张并行生图（2-10张，同时提交）。传 prompts 数组，一次调用，禁止循环调 generate_image。返回多行 ![...](C:/...png)。模型:${MODELS_HELP}`,
  {
    prompts: z
      .array(z.string().min(1))
      .min(2)
      .max(10)
      .describe("每张图一个 prompt，最多10条，并行生成"),
    model: z.enum(MODEL_OPTIONS).optional(),
    resolution: z.string().optional(),
    aspectRatio: z.string().optional(),
  },
  async (args) => {
    const { lines, okCount, total } = await runBatchAndBuildMarkdown(args);
    return {
      content: [
        {
          type: "text",
          text: lines.join("\n"),
        },
      ],
    };
  },
);

server.tool(
  "list_image_models",
  "仅用户问有哪些模型时调用。",
  {},
  async () => ({
    content: [
      {
        type: "text",
        text: listSupportedModels()
          .map((item) => item.model)
          .join("\n"),
      },
    ],
  }),
);

const transport = new StdioServerTransport();
await server.connect(transport);
