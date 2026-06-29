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
  const urls = extractAllImageUrls(data);
  return urls[0] ?? "";
}

export function extractAllImageUrls(data) {
  if (data?.results?.length > 0) {
    return data.results.map((item) => item?.url).filter(Boolean);
  }
  if (typeof data?.url === "string" && data.url) {
    return [data.url];
  }
  return [];
}

function mimeFromUrl(url) {
  const lower = url.split("?")[0].toLowerCase();
  if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
  if (lower.endsWith(".webp")) return "image/webp";
  if (lower.endsWith(".gif")) return "image/gif";
  return "image/png";
}

/** 下载 CDN 图片为 MCP 可内嵌的 base64（Codex 无法直接加载外链 Markdown 图） */
export async function fetchImageContent(imageUrl, { retries = 6, delayMs = 2000 } = {}) {
  let lastError;
  for (let attempt = 0; attempt < retries; attempt += 1) {
    if (attempt > 0) {
      await new Promise((resolve) => setTimeout(resolve, delayMs * attempt));
    }
    try {
      const res = await fetch(imageUrl, {
        headers: { "User-Agent": "cobabaai-image-plugin/0.2.2" },
        signal: AbortSignal.timeout(120_000),
      });
      if (!res.ok) {
        throw new Error(`下载图片失败 (${res.status})`);
      }
      const mimeType =
        res.headers.get("content-type")?.split(";")[0]?.trim() ||
        mimeFromUrl(imageUrl);
      const buffer = Buffer.from(await res.arrayBuffer());
      if (buffer.length === 0) {
        throw new Error("下载的图片为空");
      }
      return {
        mimeType,
        data: buffer.toString("base64"),
        bytes: buffer.length,
        buffer,
      };
    } catch (error) {
      lastError = error;
      console.error(
        `[cobabaai-image] fetch attempt ${attempt + 1}/${retries} failed:`,
        error.message,
      );
    }
  }
  throw lastError ?? new Error("下载图片失败");
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
      const imageUrls = extractAllImageUrls(data);
      if (imageUrls.length === 0) {
        throw new Error("任务成功但未返回图片 URL");
      }
      return {
        taskId,
        status: data.status,
        progress: data.progress ?? 100,
        imageUrl: imageUrls[0],
        imageUrls,
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
  resolution,
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
    resolution,
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
    aspectRatio: body.aspectRatio,
    resolution: resolution || aspectRatio || body.aspectRatio,
    imageUrls: result.imageUrls ?? [result.imageUrl],
  };
}

/** 多 prompt 并行生图（最多 10 张） */
export async function generateImagesBatch({
  prompts,
  model,
  aspectRatio,
  resolution,
}) {
  const list = prompts.map((p) => String(p).trim()).filter(Boolean).slice(0, 10);
  if (list.length === 0) {
    throw new Error("prompts 不能为空");
  }

  return Promise.all(
    list.map(async (prompt, index) => {
      try {
        const result = await generateImage({
          prompt,
          model,
          aspectRatio,
          resolution,
        });
        return { index, ok: true, prompt, ...result };
      } catch (error) {
        return {
          index,
          ok: false,
          prompt,
          error: error instanceof Error ? error.message : String(error),
        };
      }
    }),
  );
}

export function listSupportedModels() {
  return MODEL_OPTIONS.map((model) => ({
    model,
    supportsImageSize: supportsImageSize(model),
  }));
}
