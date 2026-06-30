import { existsSync, readFileSync } from "node:fs";
import { extname, normalize } from "node:path";

function mimeFromExt(ext) {
  const lower = ext.toLowerCase();
  if (lower === ".jpg" || lower === ".jpeg") return "image/jpeg";
  if (lower === ".webp") return "image/webp";
  if (lower === ".gif") return "image/gif";
  return "image/png";
}

function isHttpUrl(value) {
  return /^https?:\/\//i.test(value);
}

/** 本地路径或 URL → CobabaAi API 可用的 images 项（URL 或 base64 data URI） */
export function resolveReferenceImages({
  referenceImagePaths = [],
  referenceUrls = [],
} = {}) {
  const images = [];

  for (const raw of referenceUrls) {
    const url = String(raw ?? "").trim();
    if (url) {
      images.push(url);
    }
  }

  for (const raw of referenceImagePaths) {
    const filePath = normalize(String(raw ?? "").trim());
    if (!filePath) {
      continue;
    }
    if (isHttpUrl(filePath)) {
      images.push(filePath);
      continue;
    }
    if (!existsSync(filePath)) {
      throw new Error(`参考图不存在: ${filePath}`);
    }
    const buffer = readFileSync(filePath);
    if (buffer.length === 0) {
      throw new Error(`参考图为空: ${filePath}`);
    }
    const mime = mimeFromExt(extname(filePath));
    images.push(`data:${mime};base64,${buffer.toString("base64")}`);
  }

  return images;
}
