import {
  fetchImageContent,
  generateImagesBatch,
} from "./cobabaai-client.js";
import { buildLocalImageMarkdown, saveOriginalPng } from "./save-image.js";

export async function runBatchAndBuildMarkdown({
  prompts,
  model,
  resolution,
  aspectRatio,
}) {
  const results = await generateImagesBatch({
    prompts,
    model,
    resolution,
    aspectRatio,
  });

  const lines = [];
  for (const item of results) {
    if (!item.ok) {
      lines.push(`<!-- 第${item.index + 1}张失败: ${item.error} -->`);
      continue;
    }
    const image = await fetchImageContent(item.imageUrl);
    const savedPath = saveOriginalPng(
      image.buffer,
      `${item.taskId}_${item.index + 1}`,
    );
    lines.push(buildLocalImageMarkdown(savedPath, item.prompt));
  }

  const okCount = results.filter((r) => r.ok).length;
  if (okCount === 0) {
    throw new Error("批量生图全部失败");
  }

  return { lines, okCount, total: results.length };
}
