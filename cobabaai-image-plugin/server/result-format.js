import { fetchImageContent } from "./cobabaai-client.js";
import {
  buildLocalImageMarkdown,
  buildRefHint,
  saveOriginalPng,
} from "./save-image.js";

/** 下载 CDN 图、落盘，返回 Markdown 行（含继续编辑用的路径注释） */
export async function formatGenerationResult(result) {
  const urls = result.imageUrls?.length ? result.imageUrls : [result.imageUrl];
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
    lines.push(buildRefHint(savedPath));
  }

  return lines;
}
