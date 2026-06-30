import { resolveReferenceImages } from "./resolve-reference-images.js";

/** 统一 batch 输入：items（每条可独立垫图）或 prompts（共用垫图） */
export function normalizeBatchInput({
  items,
  prompts,
  referenceImagePaths,
  referenceUrls,
}) {
  if (Array.isArray(items) && items.length > 0) {
    if (items.length < 2) {
      throw new Error("items 至少 2 条");
    }
    return items.map((item, index) => ({
      index,
      prompt: String(item.prompt ?? "").trim(),
      referenceImagePaths: item.referenceImagePaths,
      referenceUrls: item.referenceUrls,
    }));
  }

  if (Array.isArray(prompts) && prompts.length > 0) {
    if (prompts.length < 2) {
      throw new Error("prompts 至少 2 条");
    }
    return prompts.map((prompt, index) => ({
      index,
      prompt: String(prompt).trim(),
      referenceImagePaths,
      referenceUrls,
    }));
  }

  throw new Error("须传 items（每条可独立垫图）或 prompts");
}

export function resolveBatchItemReferences(entry, sharedReferenceImages) {
  const itemRefs = resolveReferenceImages({
    referenceImagePaths: entry.referenceImagePaths,
    referenceUrls: entry.referenceUrls,
  });
  if (itemRefs.length > 0) {
    return itemRefs;
  }
  return sharedReferenceImages;
}
