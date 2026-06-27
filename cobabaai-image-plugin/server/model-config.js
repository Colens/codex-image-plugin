export const DEFAULT_BASE_URL = "https://api.cobabaai.com";

export const MODEL_OPTIONS = [
  "gpt-image-2",
  "gpt-image-2-vip",
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
  variants = 1,
  referenceUrls = [],
  imageSize,
  webHook = "-1",
}) {
  const normalizedModel = normalizeModel(model);
  const body = {
    prompt,
    variants,
    model: normalizedModel,
    urls: referenceUrls,
    webHook,
    aspectRatio,
  };

  if (supportsImageSize(normalizedModel)) {
    body.imageSize = imageSize || defaultImageSize(normalizedModel);
  }

  return body;
}

function defaultImageSize(model) {
  if (model === "nano-banana-pro-4k-vip" || model === "nano-banana-2-4k-cl") {
    return "4K";
  }
  return "1K";
}
