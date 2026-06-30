# CobabaAi 生图 × Codex

在 [Codex](https://openai.com/codex/) 对话里直接用自然语言出图。安装本插件后，说「用 gpt-image-2 画一张…」或「并行生成 5 张不同风格的…」，Codex 会自动调用 CobabaAi 生图 API，并在聊天框里展示图片。

**v0.3.3：** 单一 MCP 工具 `cobabaai_draw`，@ 插件后 **零废话直接出图**；支持垫图、继续编辑、批量并行（张数不限）。

**仓库地址：** https://github.com/Colens/codex-image-plugin

> **许可说明：** 本仓库为 **Public**，便于 Codex GitHub 插件市场安装，但采用 **专有许可**（见 [`LICENSE`](LICENSE)）——**禁止商用、禁止二次分发、禁止 Fork 后公开传播**。使用即表示同意协议条款。

---

## 功能说明

| 功能 | 说明 |
|------|------|
| **对话式出图** | 用中文或英文描述画面，Codex 自动选模型并生成 |
| **批量并行** | 2 张起、张数不限，不同描述 **一次并行** 提交，无需循环调用 |
| **多模型支持** | `gpt-image-2`、`nano-banana`、`nano-banana-pro` 等 10 种模型 |
| **图生图 / 垫图** | 上传参考图或传入本地 PNG 路径，按参考内容继续生成 |
| **继续编辑** | 基于 `~/.codex/cobabaai-images/` 已生成图再改，无需重新上传 |
| **自动轮询** | 异步任务自动等待完成，无需手动查进度 |
| **聊天内展示** | 图片保存到本地，以 Markdown 形式显示在 Codex 对话中 |
| **零 Node 配置** | 安装脚本自动下载便携 Node，无需单独安装 Node.js |

### 插件提供的 MCP 工具

v0.3.3 起只暴露 **一个** 工具，避免 AI 找入口、读说明、空转：

| 工具 | 用途 |
|------|------|
| `cobabaai_draw` | **唯一入口**：单张 / 垫图 / 变体 / 批量（`items` / `prompts`） |

#### 单张 / 垫图 / 变体

| 参数 | 说明 |
|------|------|
| `prompt` | 画面描述（单张必填） |
| `model` | 可选；**有参考图且未指定时默认 `nano-banana-2`** |
| `resolution` / `aspectRatio` | 如 `1280x1280`、`16:9`、`4K` |
| `variants` | 同 prompt 出 2～4 张变体 |
| `referenceImagePaths` | 本地绝对路径数组（用户附件、`cobabaai-images/` 下 PNG） |
| `referenceUrls` | 公网参考图 URL 数组 |

工具返回 Markdown 图片行 + 隐藏注释 `<!-- cobabaai-ref: C:/... -->`，供下一轮继续编辑时传入 `referenceImagePaths`。

#### 批量（`items` 或 `prompts`，2 条起）

**模式 A — `items`（每张不同垫图，如 10 张产品各配模特）**

| 参数 | 说明 |
|------|------|
| `items` | 数组，每项 `{ prompt, referenceImagePaths?, referenceUrls? }` |
| `model` / `resolution` | 全局共用 |

**模式 B — `prompts`（纯文生或共用一张垫图）**

| 参数 | 说明 |
|------|------|
| `prompts` | 字符串数组 |
| `referenceImagePaths` | 可选，**所有 prompt 共用** |

**对话示例：**

```
用 nano-banana-2 并行生成 5 张不同风格的赛博朋克城市，1280x1280
```

```
用 gpt-image-2 同时画 3 种不同配色的 logo，1024x1024
```

插件会用 `Promise.all` 并行提交全部任务，全部完成后返回多行本地 Markdown 图片。Skill 要求 AI **原样贴进回复**，不加解释文字。

**对比：**

| 场景 | `cobabaai_draw` 参数 |
|------|----------------------|
| 1 张纯文生图 | `prompt` |
| 1 张垫图 / 继续编辑 | `prompt` + **`referenceImagePaths`** |
| 同描述要 2～4 个变体 | `prompt` + `variants: 2~4` |
| 2 张及以上 **不同描述**（纯文生） | **`prompts`** |
| **多张各用不同垫图**（10 产品图各配模特） | **`items`** |
| 批量 + **共用一张**垫图 | `prompts` + `referenceImagePaths` |

### 支持的模型

| 系列 | 模型 | 适用场景 |
|------|------|----------|
| GPT Image | `gpt-image-2` | 默认，通用出图 |
| Nano Banana | `nano-banana` | 标准质量 |
| Nano Banana Pro | `nano-banana-pro` / `nano-banana-pro-vip` | 高质量，支持 1K/2K/4K |
| Nano Banana Pro | `nano-banana-pro-4k-vip` | 4K 高清 |
| Nano Banana 2 | `nano-banana-2` / `nano-banana-2-cl` / `nano-banana-2-4k-cl` | **垫图 / 继续编辑默认** |

完整列表见 [`cobabaai-image-plugin/server/model-config.js`](cobabaai-image-plugin/server/model-config.js)。

---

## 安装方式

> **重要：** GitHub 插件市场只注册插件元数据。仓库 **不含** `node_modules`，**必须运行安装脚本** 才能完成 npm 依赖安装、便携 Node 部署和 `config.toml` MCP 配置。

### 方式 A：一键安装（推荐）

**Windows**

1. 克隆或下载仓库
2. 双击 **`一键安装.bat`**（或运行 `install.ps1`）
3. 双击 **`配置密钥.bat`**（或运行 `configure-key.ps1`）
4. **完全退出并重启 Codex** → 新建对话 → **@ 插件** → 勾选 **CobabaAi 生图**

**macOS**

1. 克隆或下载仓库
2. 双击 **`一键安装.command`**（或运行 `./install.sh`）
3. 双击 **`配置密钥.command`**（或运行 `./configure-key.sh`）
4. 重启 Codex → 新建对话 → @ 插件 → 启用 **CobabaAi 生图**

### 方式 B：命令行安装

**Windows（PowerShell）**

```powershell
git clone https://github.com/Colens/codex-image-plugin.git
cd codex-image-plugin
powershell -ExecutionPolicy Bypass -File .\install.ps1
powershell -ExecutionPolicy Bypass -File .\configure-key.ps1
```

**macOS / Linux**

```bash
git clone https://github.com/Colens/codex-image-plugin.git
cd codex-image-plugin
chmod +x install.sh configure-key.sh scripts/*.sh doctor.sh
./install.sh
./configure-key.sh
```

macOS 若提示找不到 `codex` 命令：

```bash
export CODEX_BIN="/Applications/Codex.app/Contents/Resources/codex"
./install.sh
```

安装脚本会自动完成：

- 下载或使用便携 Node.js
- 安装 MCP 依赖并构建插件
- 部署到 `~/.codex/marketplaces/cobabaai/`
- 注册 GitHub 插件市场 `Colens/codex-image-plugin`
- 安装插件 `cobabaai-image@cobabaai`
- 写入 `~/.codex/config.toml` 中的 MCP 配置

### 方式 C：Codex GitHub 插件市场

适用于已在 Codex 中使用插件市场的用户。市场安装 **不能替代** 安装脚本。

**步骤 1 — 添加 GitHub 市场（Codex CLI 或 Codex 设置界面）**

```bash
codex plugin marketplace add Colens/codex-image-plugin --enable plugins
```

**步骤 2 — 安装插件**

```bash
codex plugin add cobabaai-image@cobabaai --enable plugins
```

或在 Codex Desktop：**设置 → 插件 → 添加市场** → 输入 `Colens/codex-image-plugin` → 安装 **CobabaAi 生图**。

**步骤 3 — 运行安装脚本（必做）**

```powershell
# Windows
git clone https://github.com/Colens/codex-image-plugin.git
cd codex-image-plugin
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

```bash
# macOS
git clone https://github.com/Colens/codex-image-plugin.git
cd codex-image-plugin
./install.sh
```

**步骤 4 — 配置密钥、重启 Codex、@ 启用插件**

### 验证安装

```bash
codex plugin list
```

应看到：

```
cobabaai-image@cobabaai  →  installed, enabled
```

---

## 环境配置

### 运行环境要求

| 项目 | 要求 |
|------|------|
| **操作系统** | Windows 10 及以上，或 macOS（Apple Silicon / Intel） |
| **Codex** | 已安装 [Codex Desktop](https://openai.com/codex/) |
| **CobabaAi 账号** | 在 [cobabaai.com](https://cobabaai.com/) 注册，并创建 API 令牌 |
| **磁盘空间** | 约 200 MB（便携 Node + 插件依赖） |
| **Git** | 可选；也可在 GitHub 下载 ZIP 解压 |

### 无需单独安装

| 软件 | 说明 |
|------|------|
| **Node.js** | ❌ 不需要。安装脚本自动下载便携版 Node **v20.18.0** |
| **Python / Java 等** | ❌ 不需要 |

### 网络要求

| 阶段 | 是否需要联网 | 访问地址 |
|------|--------------|----------|
| **安装插件** | 需要 | `nodejs.org`、`registry.npmjs.org` |
| **配置令牌** | 不需要 | 本地写入 |
| **日常出图** | 需要 | `api.cobabaai.com` |

### 安装后本机目录

| 路径 | 作用 |
|------|------|
| `~/.codex/cobabaai-image.env` | **API 令牌**（客户需填写） |
| `~/.codex/config.toml` | Codex 主配置，安装脚本自动写入 MCP 段 |
| `~/.codex/packages/node/` | 便携 Node 运行时 |
| `~/.codex/marketplaces/cobabaai/` | 插件 marketplace 与插件文件 |
| `~/.codex/cobabaai-images/` | 生成的 PNG 图片 |

Windows 示例：

```
C:\Users\你的用户名\.codex\cobabaai-image.env
C:\Users\你的用户名\.codex\marketplaces\cobabaai\plugins\cobabaai-image\
C:\Users\你的用户名\.codex\cobabaai-images\
```

### 配置文件说明

#### API 令牌文件（必配）

路径：`~/.codex/cobabaai-image.env`

```env
COBABAAI_API_KEY=sk-粘贴你的完整令牌
# 可选：COBABAAI_IMAGE_MODEL=gpt-image-2
```

#### Codex MCP 配置（自动写入）

```toml
[plugins."cobabaai-image@cobabaai".mcp_servers.cobabaai-image]
enabled = true
command = "C:\\Users\\你的用户名\\.codex\\packages\\node\\node.exe"
args = ["server/index.js"]
cwd = "C:/Users/你的用户名/.codex/marketplaces/cobabaai/plugins/cobabaai-image"
default_tools_approval_mode = "auto"
tool_timeout_sec = 600
env_vars = ["COBABAAI_API_KEY", "COBABAAI_IMAGE_MODEL"]
```

修改配置后，**重启 Codex 或新开对话** 生效。

---

## 获取并配置 API 令牌

1. 打开 **[https://cobabaai.com/](https://cobabaai.com/)** 并登录
2. 进入 **控制台 → 令牌管理**
3. 创建令牌，复制以 **`sk-`** 开头的完整字符串
4. 运行 **`配置密钥.bat`**（Windows）或 **`./configure-key.sh`**（macOS），粘贴令牌

> ⚠️ 令牌只显示一次，切勿提交到 GitHub 或分享给他人。

---

## 使用示例

### 单张出图

```
画一只在月球上喝咖啡的猫
```

```
用 gpt-image-2 画一只在月球上喝酒的猫，1280x1280
```

```
用 nano-banana 画一张赛博朋克风格的猫，16:9
```

### 十张产品图各配模特（并行垫图）

上传 10 张产品图，@ CobabaAi 生图：

```
帮我在每张产品图上都配一个美女模特，自然展示产品，写实摄影，1280x1280
```

AI 应一次调用 `cobabaai_draw`，`items` 里 10 条，每条 `referenceImagePaths` 对应一张上传图。

### 批量并行（2 张起，纯文生）

```
用 nano-banana-2 并行生成 5 张不同家具的白底产品图，1280x1280
```

```
用 gpt-image-2 同时生成 3 种不同风格的 app 图标，1024x1024
```

### 垫图 / 图生图（上传参考图）

在对话里 **@ CobabaAi 生图**，**上传一张图片** 并描述要生成的内容：

```
用 nano-banana-2 生成一位美女坐在同款白色豆袋沙发上，写实摄影，1280x1280
```

插件会把用户附件的本地路径作为 `referenceImagePaths` 传给 API。

### 继续编辑（基于已生成的图）

```
把背景改成夜景，人物和沙发不变
```

AI 会使用上一轮返回的 `<!-- cobabaai-ref: C:/Users/.../cobabaai-images/task_xxx.png -->` 路径作为垫图。

也可用公网 URL：

```
用 nano-banana-pro 根据这张参考图生成类似风格：https://example.com/ref.jpg
```

> **说明：** 有参考图时，若你指定 `gpt-image-2`，插件会自动改用 `nano-banana-2` 做垫图（效果更好）。纯文生图仍可用 `gpt-image-2`。

> **注意：** 若 AI 说「工具未连接」或反复排查却不生图，**不要**让它读 `cobabaai-image.env`。请运行 **`自检.bat`** / **`doctor.ps1`**，然后**完全重启 Codex**，新对话并在 **@ 插件** 中启用 **CobabaAi 生图**。

---

## 让 Codex 帮你安装

在新对话中说：

```
请帮我从 GitHub 安装 CobabaAi 生图插件：
https://github.com/Colens/codex-image-plugin.git
安装完成后让我粘贴 API 密钥。
```

Codex 会读取 [`AGENTS.md`](AGENTS.md) 并自动执行安装。

---

## 故障排查

| 问题 | 解决方法 |
|------|----------|
| **未配置令牌 / 401** | 确认 `~/.codex/cobabaai-image.env` 中 `COBABAAI_API_KEY=sk-...` 正确 |
| **npm / Node 下载失败** | 检查 nodejs.org、registry.npmjs.org 网络；重跑安装脚本 |
| **@ 插件里看不到 CobabaAi 生图** | 重跑 install 脚本，完全重启 Codex |
| **工具未暴露 / 无法生图** | 运行 `doctor.ps1` / `doctor.sh`，重跑 install，完全重启 Codex |
| **AI 废话多、先读说明再找入口** | 更新到 v0.3.3+，**新开对话** @ CobabaAi 生图；同垫图要 2 张用 `variants:2` 勿 batch |
| **AI 反复排查、弹权限读 .env** | 不要批准；重启 Codex → 新对话 @ CobabaAi 生图 |
| **插件列表为空** | `codex plugin marketplace add Colens/codex-image-plugin --enable plugins`，再 `codex plugin add cobabaai-image@cobabaai --enable plugins`，然后重跑 install |
| **macOS 找不到 codex** | `export CODEX_BIN="/Applications/Codex.app/Contents/Resources/codex"` |
| **生成超时** | 批量或 pro 系列较慢，超时已设 600 秒；可换 `nano-banana` |
| **图片不显示** | 工具返回 `![...](C:/Users/.../cobabaai-images/xxx.png)`，模型须原样贴进回复 |

---

## 目录结构

```
codex-image-plugin/
├── .agents/plugins/marketplace.json   # GitHub 市场清单
├── LICENSE                            # 专有许可
├── 一键安装.bat / .command            # 一键安装
├── 配置密钥.bat / .command
├── 自检.bat / .command
├── install.ps1 / install.sh
├── configure-key.ps1 / .sh
├── doctor.ps1 / doctor.sh
├── AGENTS.md
└── cobabaai-image-plugin/             # 插件主体
    ├── .codex-plugin/plugin.json
    ├── server/                        # MCP Server
    └── skills/                        # 生图 Skill
```

---

## 相关链接

- [CobabaAi 官网](https://cobabaai.com/)
- [CobabaAi API 文档](https://cobabaai.com/docs/zh/guide/api.html)
- [Codex 官网](https://openai.com/codex/)
- [GitHub 仓库](https://github.com/Colens/codex-image-plugin)

---

## 许可证

本软件采用 **CobabaAi 专有软件许可协议**（见 [`LICENSE`](LICENSE)）：

- ✅ 个人非商业使用
- ❌ 禁止商用
- ❌ 禁止二次分发、转售、Fork 后公开传播
- GitHub Public **不等于** 开源

API 令牌属于敏感信息，请妥善保管。商业授权请联系 [cobabaai.com](https://cobabaai.com/)。
