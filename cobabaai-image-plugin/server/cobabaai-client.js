import {
  DEFAULT_BASE_URL,
  buildRequestBody,
  getEndpoint,
  normalizeModel,
  supportsImageSize,
  MODEL_OPTIONS,
} from "./model-config.js";
import { loadLocalConfig, localConfigPath } from "./load-local-config.js";

const POLL_INTERVAL_MS = 5000;
const MAX_POLL_ATTEMPTS = 120;

loadLocalConfig();

export function getApiKey() {
  const key = process.env.COBABAAI_API_KEY?.trim();
  if (!key) {
    throw new Error(
      [
        "未配置 CobabaAi API 密钥。",
        "请任选一种方式：",
        "1. Windows: 双击「配置密钥.bat」",
        "2. macOS: 运行 ./configure-key.sh",
        `3. 编辑 ${localConfigPath()}，写入 COBABAAI_API_KEY=sk-你的密钥`,
      ].join("\n"),
    );
  }
  return key;
}

export function getBaseUrl() {
  return (process.env.COBABAAI_BASE_URL || DEFAULT_BASE_URL).replace(/\/$/, "");
}

async function parseApiError(res) {
  try {
    const data = await res.json();
    return (
      data?.msg ||
      data?.error?.message ||
      data?.message ||
      `请求失败 (${res.status})`
    );
  } catch {
    return `请求失败 (${res.status})`;
  }
}

async function postJson(url, body) {
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${getApiKey()}`,
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    throw new Error(await parseApiError(res));
  }

  const data = await res.json();
  if (data.code !== 0) {
    throw new Error(data.msg || "CobabaAi 生图请求失败");
  }

  return data;
}

function extractImageUrl(data) {
  if (data?.results?.length > 0 && data.results[0]?.url) {
    return data.results[0].url;
  }
  if (typeof data?.url === "string" && data.url) {
    return data.url;
  }
  return "";
}

export async function pollImageTask(taskId) {
  const baseUrl = getBaseUrl();

  for (let attempt = 0; attempt < MAX_POLL_ATTEMPTS; attempt += 1) {
    const result = await postJson(`${baseUrl}/v1/draw/result`, { id: taskId });

    if (result.code === -22) {
      throw new Error("生图任务超时");
    }

    const data = result.data;

    if (data.status === "running") {
      await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL_MS));
      continue;
    }

    if (data.status === "succeeded") {
      const imageUrl = extractImageUrl(data);
      if (!imageUrl) {
        throw new Error("任务成功但未返回图片 URL");
      }
      return {
        taskId,
        status: data.status,
        progress: data.progress ?? 100,
        imageUrl,
      };
    }

    if (data.status === "failed") {
      throw new Error(data.error || data.failure_reason || "生图失败");
    }

    await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL_MS));
  }

  throw new Error("轮询超时，请稍后重试");
}

export async function generateImage({
  prompt,
  model,
  aspectRatio,
  variants,
  referenceUrls,
  imageSize,
}) {
  const normalizedModel = normalizeModel(model || process.env.COBABAAI_IMAGE_MODEL);
  const baseUrl = getBaseUrl();
  const endpoint = getEndpoint(baseUrl, normalizedModel);
  const body = buildRequestBody({
    prompt,
    model: normalizedModel,
    aspectRatio,
    variants,
    referenceUrls,
    imageSize,
  });

  const submit = await postJson(endpoint, body);
  const taskId = submit.data?.id;
  if (!taskId) {
    throw new Error("未返回任务 ID");
  }

  const result = await pollImageTask(taskId);
  return {
    ...result,
    model: normalizedModel,
    prompt,
    aspectRatio: aspectRatio || "auto",
  };
}

export function listSupportedModels() {
  return MODEL_OPTIONS.map((model) => ({
    model,
    supportsImageSize: supportsImageSize(model),
  }));
}
