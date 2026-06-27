# CobabaAi 生图 × Codex 集成方案

> 项目背景文档：汇总 CobabaAi 生图能力接入 Codex 的可行性讨论、Skill vs Plugin 选型、以及与本仓库编排层的关系。  
> 供后续 Agent 直接读取并执行。

---

## 1. 讨论背景

用户询问：**是否可以做一个 Codex 的生图插件，配置 CobabaAi 的生图接口和密钥？**

后续追问：**做成 Skill 好还是 Plugin 好？**

本文记录上述讨论的结论与推荐落地路径。

---

## 2. 核心结论速查

| 问题 | 结论 |
|------|------|
| 能否为 Codex 接 CobabaAi 生图？ | ✅ 可以，推荐 **Codex Plugin + MCP Server** |
| 仅做 Skill 能否完成生图？ | ❌ 不能；Skill 只是 Markdown 说明，无法直接调 HTTP API |
| Skill vs Plugin 怎么选？ | **Plugin（含 MCP）为主，Skill 为辅**，二者不是互斥关系 |
| `cursor_to_everything` 是否已有生图？ | ❌ 无；当前仅 Composer 规划 + Codex 代码执行 |
| CobabaAi 是否已在其他项目使用？ | ✅ 有；`Codex-Chinese-Setup` 已配置 CobabaAi 作对话模型后端 |

---

## 3. CobabaAi 生图 API 概要

### 3.1 基础信息

| 项目 | 值 |
|------|-----|
| API 地址 | `https://cobabaai.com/v1` |
| 认证方式 | `Authorization: Bearer sk-...` |
| 内容类型 | `application/json` |
| 密钥来源 | 控制台 → 令牌管理 |

### 3.2 主要生图接口

| 接口 | 用途 | 典型模型 |
|------|------|----------|
| `POST /v1/images/generations` | OpenAI 兼容同步出图 | `gpt-image-2` |
| `POST /v1/api/generate` | 统一 JSON 出图 | `nano-banana-fast` 等 |
| `POST /v1/draw/nano-banana` | 提交异步任务 | Nano Banana 系列 |
| `POST /v1/draw/result` | 查询异步结果 | 配合上述接口，不重复扣费 |

### 3.3 同步出图示例

```bash
curl https://cobabaai.com/v1/images/generations \
  -H "Authorization: Bearer sk-你的令牌" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-image-2",
    "prompt": "A cute cat drinking coffee on the moon",
    "size": "1024x1024"
  }'
```

### 3.4 统一 JSON 出图（含异步）

```bash
curl https://cobabaai.com/v1/api/generate \
  -H "Authorization: Bearer sk-你的令牌" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nano-banana-fast",
    "prompt": "A cat on the moon",
    "images": [],
    "aspectRatio": "1:1",
    "imageSize": "1K",
    "replyType": "async"
  }'
```

`replyType: async` 时返回任务 id，需再调 `/v1/draw/result` 轮询。

### 3.5 参考文档

- 父仓库：`D:\githubproject\new-api\docs-site\zh\guide\api.md`
- 官方：https://cobabaai.com/docs/zh/guide/api.html

---

## 4. Codex 侧集成机制

### 4.1 Skill 是什么

- 本质是 `skills/<name>/SKILL.md` 中的 **Markdown 使用说明**
- 教 Codex **何时、如何** 处理某类任务
- **不能** 自行执行 HTTP 请求或持有 API 调用逻辑

### 4.2 Plugin 是什么

- 入口：`.codex-plugin/plugin.json`
- 可打包：
  - `skills/` — 行为说明
  - `.mcp.json` — MCP Server 配置（**真正可调 API 的工具层**）
  - `hooks/` — 生命周期钩子
  - `apps` — App Connector
- 安装后用户可在 `~/.codex/config.toml` 中启用/禁用及配置工具审批策略

### 4.3 MCP 是什么

- Model Context Protocol：给 Codex 提供 **可调用工具**
- 配置位置：`~/.codex/config.toml` 的 `[mcp_servers.*]`，或 Plugin 内 `.mcp.json`
- Codex 工具名格式：`mcp__<server-name>__<tool_name>`
- 支持 STDIO（本地进程）与 Streamable HTTP 两种传输

### 4.4 官方选型建议（摘自 Codex 文档）

> 若仍在个人仓库内迭代单一工作流 → 先做 **local skill**。  
> 若要跨团队分享、打包 MCP、稳定分发 → 做 **Plugin**。

生图属于需要 **稳定 API 调用 + 密钥管理 + 异步轮询** 的场景，应走 Plugin 路线。

---

## 5. Skill vs Plugin 对比

| 维度 | 仅 Skill | Plugin + MCP | Plugin + MCP + Skill |
|------|----------|--------------|----------------------|
| 能否调 CobabaAi API | ❌ 只能靠 curl/shell，不推荐 | ✅ | ✅ |
| 密钥安全 | ❌ 易暴露在命令行/日志 | ✅ 环境变量注入 | ✅ |
| 异步模型（nano-banana） | ❌ 难稳定实现 | ✅ MCP 内轮询 | ✅ |
| 教 Codex 何时出图 | ✅ | ⚠️ 可能不知道何时用 | ✅ 最佳 |
| 团队分发 / marketplace | ❌ | ✅ | ✅ |
| 实现复杂度 | 低（但功能不完整） | 中 | 中 |

### 5.1 仅 Skill 的问题

若 Skill 只写「需要出图时用 curl 调 CobabaAi」：

1. API Key 可能出现在 shell 历史与日志中
2. 异步任务需手动轮询，Skill 无法封装
3. 错误处理、超时、重试不稳定
4. 每次依赖 shell 批准，体验差

### 5.2 最终建议

**不是二选一，而是分层组合：**

```
Plugin（容器）
├── MCP Server（核心能力：调 CobabaAi API）
└── Skill（辅助：何时出图、选哪个模型、参数怎么填）
```

- **MCP** = 真正生图
- **Skill** = 使用说明书
- **Plugin** = 把两者打包成可安装、可分享单元

---

## 6. 推荐架构：CobabaAi 生图 Plugin

### 6.1 目录结构

```
cobabaai-image-plugin/
├── .codex-plugin/
│   └── plugin.json          # 插件清单
├── .mcp.json                # MCP 配置（密钥建议走 env_vars）
├── server/
│   └── index.ts             # MCP 服务，暴露生图工具
├── skills/
│   └── image-gen/
│       └── SKILL.md         # 可选但建议：出图场景与模型选择指南
├── package.json
└── README.md
```

### 6.2 plugin.json 示例

```json
{
  "name": "cobabaai-image",
  "version": "0.1.0",
  "description": "CobabaAi 生图 MCP 插件",
  "skills": "./skills/",
  "mcpServers": "./.mcp.json",
  "interface": {
    "displayName": "CobabaAi 生图",
    "shortDescription": "在 Codex 中调用 CobabaAi 出图"
  }
}
```

### 6.3 .mcp.json 示例

```json
{
  "mcpServers": {
    "cobabaai-image": {
      "command": "node",
      "args": ["server/index.js"],
      "cwd": ".",
      "env": {
        "COBABAAI_BASE_URL": "https://cobabaai.com/v1",
        "COBABAAI_IMAGE_MODEL": "gpt-image-2"
      }
    }
  }
}
```

**密钥安全：** 不要将 `COBABAAI_API_KEY` 写入仓库；使用系统环境变量，或在 `config.toml` 中通过 `env_vars = ["COBABAAI_API_KEY"]` 转发。

### 6.4 建议暴露的 MCP 工具

| 工具名 | 作用 | 对应接口 |
|--------|------|----------|
| `generate_image` | 同步出图 | `POST /v1/images/generations` |
| `generate_image_unified` | 统一 JSON 出图 | `POST /v1/api/generate` |
| `poll_image_task` | 异步轮询 | `POST /v1/draw/result` |

### 6.5 用户侧 config.toml 策略（可选）

```toml
[plugins."cobabaai-image".mcp_servers.cobabaai-image]
enabled = true
default_tools_approval_mode = "prompt"
tool_timeout_sec = 300
```

异步模型（如 `nano-banana-fast`）建议增大 `tool_timeout_sec`（默认 60 秒可能不够）。

### 6.6 数据流

```
用户
  ↓
Codex CLI / IDE
  ↓
CobabaAi 生图 Plugin
  ├─ Skill：判断是否需要出图、选模型
  └─ MCP Server：HTTP 调用 CobabaAi
        ↓
https://cobabaai.com/v1
        ↓
图片 URL / base64 → 返回 Codex → 用户
```

---

## 7. 与本仓库（cursor_to_everything）的关系

### 7.1 当前状态

| 项 | 状态 |
|----|------|
| 插件系统 | ❌ 无 |
| 生图能力 | ❌ 无 |
| Task executor | 仅 `executor: "codex"` |
| CobabaAi 引用 | 本仓库内为零 |

`cursor_to_everything` 是 **Composer 规划 + Codex 执行** 的编排中转层，见 `PROJECT.md`。

### 7.2 两条独立集成路径

| 目标 | 推荐方案 | 改动位置 |
|------|----------|----------|
| **Codex 对话/编码时主动出图** | Codex Plugin + MCP | 独立插件项目，或 `~/.codex/config.toml` |
| **Composer 自动规划生图任务** | 扩展 orchestrator executor | 本仓库 `src/schema/plan.ts`、`src/orchestrator.ts` |

二者解决不同问题，可并存。

### 7.3 若扩展本仓库编排层（方案 C）

1. 扩展 schema：`executor: z.enum(["codex", "cobabaai_image"])`
2. 新增模块：`src/adapters/cobabaai-image.ts`
3. 配置项（`config.ts` + `.env.example`）：

```env
COBABAAI_API_KEY=sk-...
COBABAAI_BASE_URL=https://cobabaai.com/v1
COBABAAI_IMAGE_MODEL=gpt-image-2
```

4. 修改 `orchestrator.ts`：按 executor 分发
5. 修改 Composer plan prompt：需要出图时生成 `executor: "cobabaai_image"` 任务
6. `TaskResult` 增加 `image_urls?: string[]`

### 7.4 若仅做 HTTP 代理（方案 B，最小改动）

仿照 `src/adapters/openai-chat.ts`，增加：

- `POST /v1/images/generations` → 转发 CobabaAi
- 可选 `POST /v1/api/generate` → 异步封装

适合让 new-api 或其他客户端直接调用，**不改动 Composer↔Codex 闭环**。

### 7.5 若复用 new-api 网关（方案 D）

- `COBABAAI_BASE_URL` 指向本地 new-api（如 `http://127.0.0.1:3000/v1`）
- 用户 Token 经 `NEW_API_REQUIRE_AUTH` 统一鉴权与计费
- 生图路由已在 `new-api/router/relay-router.go` 实现

---

## 8. 已有相关配置（父仓库）

### 8.1 Codex 对话已指向 CobabaAi

路径：`D:\githubproject\Codex-Chinese-Setup\Codex修复工具\config.toml`

```toml
model_provider = "custom"
model = "gpt-5.4"
openai_base_url = "https://cobabaai.com/v1"

[model_providers.custom]
name = "CobabaAi"
base_url = "https://cobabaai.com/v1"
wire_api = "responses"
env_key = "COBABAAI_API_KEY"
```

说明：**对话模型** 与 **生图 MCP** 可共用同一 `COBABAAI_API_KEY`，但是两个独立能力。

---

## 9. 场景选型表

| 场景 | 建议 |
|------|------|
| 自己试用、最快验证 | 直接在 `~/.codex/config.toml` 挂 MCP，不必先做完整 Plugin |
| 长期个人使用、密钥安全 | Plugin + MCP |
| 团队分享 / marketplace 分发 | Plugin + MCP + Skill |
| Composer 自动规划出图 | 扩展 `cursor_to_everything` orchestrator |
| 对外暴露生图 HTTP API | 本仓库 HTTP 代理 或 复用 new-api |

---

## 10. 实现注意点

1. **异步模型**：`nano-banana-fast` 等需在 MCP 内实现轮询，或增大 `tool_timeout_sec`
2. **密钥安全**：禁止写入前端、公开仓库、`.mcp.json` 明文（应用 env_vars）
3. **Windows**：MCP 使用 `node` + stdio 即可；本仓库 Codex spawn 已处理 `shell: true`
4. **结果摘要**：若接入 orchestrator，参考 `summarizeCodexItems` 对 image URL 做短摘要再喂给 Composer review
5. **插件变更**：安装/更新 Plugin 后通常需新开会话才能生效

---

## 11. 待决事项（实施前需确认）

- [ ] 目标场景：Codex 内出图 vs Composer 自动规划出图 vs 两者都要
- [ ] 默认生图模型：`gpt-image-2`（同步）还是 `nano-banana-fast`（异步更便宜）
- [ ] 分发方式：仅本机 `config.toml` vs 完整 Plugin + marketplace
- [ ] 是否与 new-api 共用鉴权/计费

---

## 12. 给下一 Agent 的起始 Prompt

```
请阅读 PROJECT2.md，实现 CobabaAi 生图 Codex Plugin（最小可用版）。

目标：
1. 创建独立插件目录 cobabaai-image-plugin/
2. plugin.json + .mcp.json + Node MCP Server
3. 暴露 generate_image 工具，调用 POST /v1/images/generations
4. 可选：generate_image_unified + poll_image_task（async）
5. 可选：skills/image-gen/SKILL.md 说明何时出图、模型选择
6. 密钥通过 COBABAAI_API_KEY 环境变量，不写死

约束见 PROJECT2.md §10。Windows 兼容。完成后给出安装与验证步骤。
```

若目标是扩展本仓库编排层而非 Codex Plugin，改读 PROJECT2.md §7.3，并同时参考 PROJECT.md。

---

## 13. 参考链接

- [CobabaAi API 文档](https://cobabaai.com/docs/zh/guide/api.html)
- [CobabaAi 快速开始](https://cobabaai.com/docs/zh/guide/quickstart.html)
- [Codex MCP](https://developers.openai.com/codex/mcp)
- [Codex Build Plugins](https://developers.openai.com/codex/plugins/build)
- [本仓库 PROJECT.md](./PROJECT.md) — Composer + Codex 编排主文档

---

## 14. 目录规划（建议）

```
# 方案 A：独立 Codex Plugin（推荐）
cobabaai-image-plugin/
├── .codex-plugin/plugin.json
├── .mcp.json
├── server/index.ts
├── skills/image-gen/SKILL.md
├── package.json
└── README.md

# 方案 C：扩展本仓库（可选，与 Plugin 可并存）
cursor_to_everything/
├── PROJECT2.md             # 本文件
├── src/
│   ├── adapters/
│   │   └── cobabaai-image.ts   # 待建
│   └── schema/plan.ts          # 扩展 executor
└── .env.example                # 增加 COBABAAI_* 变量
```

---

*文档生成自 CobabaAi 生图 × Codex 集成讨论会话，最后更新：2026-06-25*
