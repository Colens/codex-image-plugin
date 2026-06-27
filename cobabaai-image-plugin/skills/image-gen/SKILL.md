---
name: cobabaai-image-gen
description: 当用户要求用 CobabaAi、gpt-image-2、nano-banana 等模型生成/绘制/出图时使用。调用 MCP 工具 mcp__cobabaai-image__generate_image，并在回复中用 Markdown 图片展示结果。
---

# CobabaAi 生图

## 何时使用

用户出现以下意图时，**立即**调用 `generate_image` 工具，不要只用文字描述图片：

- 「用 CobabaAi 生成…」
- 「用 gpt-image-2 / nano-banana 画一张…」
- 「帮我出图 / 生图 / 绘图 / 做一张图…」
- 「根据这张参考图生成…」（传 `referenceUrls`）

## 工具

| 工具 | 用途 |
|------|------|
| `generate_image` | 提交生图并自动轮询，返回图片 URL（主要工具） |
| `poll_image_task` | 手动查询任务（一般不需要） |
| `list_image_models` | 列出可用模型 |

Codex 中工具名格式：`mcp__cobabaai-image__generate_image`

## 模型选择

| 用户意图 | 推荐模型 |
|----------|----------|
| 默认 / 未指定 | `gpt-image-2` |
| 快速 / 便宜 | `nano-banana-fast` |
| 高质量 | `gpt-image-2-vip` 或 `nano-banana-pro-vip` |
| 4K | `nano-banana-pro-4k-vip` / `nano-banana-2-4k-cl` |
| 用户明确指定 | 使用用户指定的模型名 |

## 参数说明

与 CobabaAi 刷图前端一致：

- `prompt`：画面描述（必填）
- `model`：模型名
- `aspectRatio`：宽高比或像素尺寸
  - gpt-image 系列：`auto`、`1024x1024`、`1536x1024` 等
  - nano-banana 系列：`auto`、`1:1`、`16:9`、`9:16` 等
- `referenceUrls`：参考图 URL 数组（图生图）
- `imageSize`：nano-banana-pro / nano-banana-2 系列可选 `1K` / `2K` / `4K`
- `variants`：生成张数，默认 1

## 回复格式

工具返回 `imageUrl` 后，**必须在回复中用 Markdown 图片展示**：

```markdown
![描述](https://返回的图片URL)
```

可同时附上模型、尺寸等简要说明。图片 CDN 链接有时效（约 2 小时），提醒用户及时保存。

## 密钥

推荐将密钥写入 **`~/.codex/cobabaai-image.env`**：
- Windows：双击 **`配置密钥.bat`**
- macOS：运行 **`./configure-key.sh`**

```env
COBABAAI_API_KEY=sk-你的密钥
```

## 示例

用户：「用 nano-banana-fast 生成一张赛博朋克风格的猫，16:9」

调用：

```json
{
  "prompt": "赛博朋克风格的猫",
  "model": "nano-banana-fast",
  "aspectRatio": "16:9"
}
```

然后在回复中嵌入返回的图片 URL。
