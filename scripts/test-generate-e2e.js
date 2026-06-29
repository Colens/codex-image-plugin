/**
 * 端到端测试：提交生图 → 轮询 → 下载图片
 * 用法: node scripts/test-generate-e2e.js
 */
import { loadLocalConfig } from "../cobabaai-image-plugin/server/load-local-config.js";
import {
  generateImage,
  fetchImageContent,
} from "../cobabaai-image-plugin/server/cobabaai-client.js";

loadLocalConfig();

const prompt = "一只猫在月球上喝酒，插画风格";
const model = "gpt-image-2";
const resolution = "1280x1280";

console.log("=== CobabaAi E2E ===");
console.log("model:", model, "resolution:", resolution);
console.log("prompt:", prompt);

const t0 = Date.now();
const result = await generateImage({ prompt, model, resolution });
console.log("generate ok", Date.now() - t0, "ms");
console.log("taskId:", result.taskId);
console.log("url:", result.imageUrl);

const t1 = Date.now();
const image = await fetchImageContent(result.imageUrl);
console.log("fetch ok", Date.now() - t1, "ms");
console.log("mime:", image.mimeType, "bytes:", image.bytes);
console.log("base64 length:", image.data.length);
console.log(
  "approx MCP payload MB:",
  ((image.data.length + 500) / 1024 / 1024).toFixed(2),
);
