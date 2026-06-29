export const DEFAULT_BASE_URL = "https://api.cobabaai.com";

export const MODEL_OPTIONS = [
  "gpt-image-2",
  "nano-banana-fast",
  "nano-banana",
  "nano-banana-pro",
  "nano-banana-pro-vt",
  "nano-banana-pro-cl",
  "nano-banana-pro-vip",
  "nano-banana-pro-4k-vip",
  "nano-banana-2",
  "nano-banana-2-cl",
  "nano-banana-2-4k-cl",
];

const NANO_BANANA_MODELS = new Set([
  "nano-banana-fast",
  "nano-banana",
  "nano-banana-pro",
  "nano-banana-pro-vt",
  "nano-banana-pro-cl",
  "nano-banana-pro-vip",
  "nano-banana-pro-4k-vip",
  "nano-banana-2",
  "nano-banana-2-cl",
  "nano-banana-2-4k-cl",
]);

export function normalizeModel(model) {
  if (typeof model !== "string" || !model.trim()) return "gpt-image-2";
  const value = model.trim();
  return MODEL_OPTIONS.includes(value) ? value : "gpt-image-2";
}

export function getEndpoint(baseUrl, model) {
  const normalized = normalizeModel(model);
  if (NANO_BANANA_MODELS.has(normalized)) {
    return `${baseUrl}/v1/draw/nano-banana`;
  }
  return `${baseUrl}/v1/draw/completions`;
}

export function supportsImageSize(model) {
  return [
    "nano-banana-pro",
    "nano-banana-pro-vt",
    "nano-banana-pro-cl",
    "nano-banana-pro-vip",
    "nano-banana-pro-4k-vip",
    "nano-banana-2",
    "nano-banana-2-cl",
    "nano-banana-2-4k-cl",
  ].includes(normalizeModel(model));
}

export function buildRequestBody({
  prompt,
  model,
  aspectRatio = "auto",
  resolution,
  variants = 1,
  referenceUrls = [],
  imageSize,
  webHook = "-1",
}) {
  const normalizedModel = normalizeModel(model);
  const size = resolveSize({
    resolution,
    aspectRatio,
    model: normalizedModel,
  });
  const body = {
    prompt,
    variants,
    model: normalizedModel,
    urls: referenceUrls,
    webHook,
    aspectRatio: size.aspectRatio,
  };

  if (supportsImageSize(normalizedModel)) {
    body.imageSize = imageSize || size.imageSize || defaultImageSize(normalizedModel);
  }

  return body;
}

function defaultImageSize(model) {
  if (model === "nano-banana-pro-4k-vip" || model === "nano-banana-2-4k-cl") {
    return "4K";
  }
  return "1K";
}

/** 把用户说的「分辨率」统一成 API 的 aspectRatio / imageSize */
export function resolveSize({ resolution, aspectRatio, model }) {
  const raw = (resolution || aspectRatio || "auto").trim();
  const upper = raw.toUpperCase();

  if (["1K", "2K", "4K"].includes(upper) && supportsImageSize(model)) {
    return { aspectRatio: aspectRatio?.trim() || "auto", imageSize: upper };
  }

  const sizeMatch = raw.match(/^(\d+)\s*[x×*]\s*(\d+)$/i);
  if (sizeMatch) {
    const w = Number(sizeMatch[1]);
    const h = Number(sizeMatch[2]);
    return { aspectRatio: raw, imageSize: inferImageSizeFromPixels(w, h, model) };
  }

  return {
    aspectRatio: raw,
    imageSize: inferImageSizeFromPixels(0, 0, model),
  };
}

function inferImageSizeFromPixels(w, h, model) {
  if (!supportsImageSize(model)) {
    return undefined;
  }
  const max = Math.max(w, h);
  if (max >= 3000) return "4K";
  if (max >= 1500) return "2K";
  if (max > 0) return "1K";
  return defaultImageSize(normalizeModel(model));
}

export const MODELS_HELP = MODEL_OPTIONS.join(", ");
