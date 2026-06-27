# CobabaAi 生图 × Codex

在 Codex 对话中说「用 CobabaAi / gpt-image-2 / nano-banana 生成图片」，即可通过 CobabaAi 生图 API 出图并在聊天框展示。

## 前置要求

- 已安装 [Codex](https://openai.com/codex/)
- 拥有 CobabaAi API 密钥（[cobabaai.com](https://cobabaai.com/) 控制台获取，sk- 开头）
- **无需单独安装 Node.js**（安装脚本会使用内置 Node 或自动下载）

> 分发策略详见 **[DISTRIBUTION.md](./DISTRIBUTION.md)**（GitHub 通道 vs 网盘离线包）

---

## Windows 一键安装

1. 克隆或下载本仓库
2. 双击 **`一键安装.bat`**
3. 按提示粘贴 API 密钥（可跳过，稍后配置）
4. **重启 Codex**，新开对话
5. 在 **@ 插件** 中确认 **CobabaAi 生图** 已安装

## macOS 一键安装

在终端中进入仓库目录，执行：

```bash
chmod +x install.sh configure-key.sh scripts/*.sh
./install.sh
```

脚本会自动下载便携 Node（若仓库内无 `packages/node`），**无需本机预装 Node.js**。

脚本会自动：

- 安装 MCP 依赖
- 部署插件到 `~/.codex/marketplaces/cobabaai-local/`
- 注册 marketplace 并安装插件
- 提示配置 API 密钥

安装完成后 **重启 Codex**，新开对话，在 **@ 插件** 中确认 **CobabaAi 生图** 已安装。

> 若提示找不到 `codex` 命令，可先安装 Codex Desktop，或指定 CLI 路径后重试：
>
> ```bash
> export CODEX_BIN="/Applications/Codex.app/Contents/Resources/codex"
> ./install.sh
> ```

---

## 配置 API 密钥

密钥保存在 **`~/.codex/cobabaai-image.env`**（Windows 路径为 `%USERPROFILE%\.codex\cobabaai-image.env`）。插件启动时自动读取，**无需配置系统环境变量**。

### Windows

| 方式 | 操作 |
|------|------|
| **最简单** | 双击 **`配置密钥.bat`**，粘贴 sk- 密钥 |
| 安装时配置 | 运行 **`一键安装.bat`** 时按提示粘贴 |
| 手动编辑 | 复制 `cobabaai-image.env.example` 到 `%USERPROFILE%\.codex\cobabaai-image.env` 并填入密钥 |

### macOS / Linux

| 方式 | 操作 |
|------|------|
| **最简单** | 在仓库目录执行 `./configure-key.sh`，粘贴 sk- 密钥 |
| 安装时配置 | 运行 `./install.sh` 时按提示粘贴 |
| 手动编辑 | 复制 `cobabaai-image.env.example` 到 `~/.codex/cobabaai-image.env` 并填入密钥 |

### 配置文件示例

```env
# ~/.codex/cobabaai-image.env
COBABAAI_API_KEY=sk-你的密钥
# 可选，默认 gpt-image-2
# COBABAAI_IMAGE_MODEL=gpt-image-2
```

### 读取优先级

1. `~/.codex/cobabaai-image.env`（推荐）
2. 系统环境变量 `COBABAAI_API_KEY`
3. Codex 插件 `env_vars` 转发

修改密钥后，**重启 Codex 或新开对话** 生效。

---

## 使用示例

```
用 gpt-image-2 生成一张月球上喝咖啡的猫，1024x1024
```

```
用 nano-banana-fast 画一张赛博朋克风格的猫，16:9
```

```
用 nano-banana-pro 根据这张参考图生成类似风格：https://example.com/ref.jpg
```

Agent 会调用 `generate_image` MCP 工具，自动提交异步任务、轮询结果，并在回复中用 Markdown 图片展示。

## 支持的模型

- `gpt-image-2` / `gpt-image-2-vip`
- `nano-banana-fast` / `nano-banana`
- `nano-banana-pro` 系列
- `nano-banana-2` 系列

完整列表见 `cobabaai-image-plugin/server/model-config.js`。

## 目录结构

```
codex_img/
├── AGENTS.md                 # 给 Codex 代装的步骤说明
├── DISTRIBUTION.md           # GitHub / 网盘 两条分发通道
├── 一键安装.bat              # Windows 一键安装
├── 配置密钥.bat              # Windows 配置密钥
├── install.sh / install.ps1
├── configure-key.sh / configure-key.ps1
├── scripts/                  # Node 内置 / 下载 / 打网盘包
├── packages/node/            # 网盘版内置 Node（Git 忽略）
├── cobabaai-image.env.example
└── cobabaai-image-plugin/
```

## 环境变量

| 变量 | 必填 | 说明 |
|------|------|------|
| `COBABAAI_API_KEY` | 是 | CobabaAi API 密钥，推荐写入 `~/.codex/cobabaai-image.env` |
| `COBABAAI_BASE_URL` | 否 | 默认 `https://api.cobabaai.com` |
| `COBABAAI_IMAGE_MODEL` | 否 | 默认模型，默认 `gpt-image-2` |

## API 说明

生图接口与参数参照 CobabaAi 刷图前端实现：

- gpt-image 系列 → `POST /v1/draw/completions`
- nano-banana 系列 → `POST /v1/draw/nano-banana`
- 轮询结果 → `POST /v1/draw/result`

## 手动安装（高级）

若脚本不可用，可手动执行：

```bash
cd cobabaai-image-plugin
npm install --omit=dev
npm run build

# 注册 marketplace 并安装插件
codex plugin marketplace add ~/.codex/marketplaces/cobabaai-local --enable plugins
codex plugin add cobabaai-image@cobabaai-local --enable plugins
```

需先将插件复制到 `~/.codex/marketplaces/cobabaai-local/plugins/cobabaai-image/`，并创建 `.agents/plugins/marketplace.json`（参考 `install.sh`）。

## 故障排查

- **未配置密钥**
  - Windows：双击 **`配置密钥.bat`**
  - macOS：运行 **`./configure-key.sh`**
  - 或编辑 `~/.codex/cobabaai-image.env`
- **config.toml 有配置但插件/技能页看不到**：重新运行安装脚本，或手动执行：
  ```bash
  codex plugin marketplace add ~/.codex/marketplaces/cobabaai-local --enable plugins
  codex plugin add cobabaai-image@cobabaai-local --enable plugins
  ```
  然后重启 Codex 并新开对话。
- **macOS 找不到 codex 命令**：设置 `export CODEX_BIN="/Applications/Codex.app/Contents/Resources/codex"` 后重试
- **插件不生效**：重启 Codex，新开对话；检查 @ 插件 → CobabaAi 生图
- **超时**：nano-banana 较慢，`tool_timeout_sec` 已设为 600 秒
- **图片链接失效**：CDN 链接约 2 小时有效，请及时保存
