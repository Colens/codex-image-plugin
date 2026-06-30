import { generateImage } from "./cobabaai-client.js";
import { runBatchAndBuildMarkdown } from "./batch-images.js";
import { formatGenerationResult } from "./result-format.js";
import { normalizeBatchInput } from "./batch-normalize.js";

export async function handleDraw(args) {
  const hasBatch =
    (Array.isArray(args.items) && args.items.length > 0) ||
    (Array.isArray(args.prompts) && args.prompts.length > 0);

  if (hasBatch) {
    normalizeBatchInput(args);
    const { lines } = await runBatchAndBuildMarkdown(args);
    return lines.join("\n");
  }

  if (!args.prompt?.trim()) {
    throw new Error("prompt 不能为空");
  }

  const lines = await formatGenerationResult(await generateImage(args));
  return lines.join("\n");
}
