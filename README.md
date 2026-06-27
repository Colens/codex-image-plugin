# CobabaAi 生图 × Codex

在 [Codex](https://openai.com/codex/) 对话里直接用自然语言出图。安装本插件后，说「用 gpt-image-2 画一张…」或「用 nano-banana 生成…」，Codex 会自动调用 CobabaAi 生图 API，并在聊天框里展示图片。

**仓库地址：** https://github.com/Colens/codex-image-plugin

---

## 功能说明

| 功能 | 说明 |
|------|------|
| **对话式出图** | 用中文或英文描述画面，Codex 自动选模型并生成 |
| **多模型支持** | `gpt-image-2`、`nano-banana-fast`、`nano-banana-pro` 等 12 种模型 |
| **图生图** | 传入参考图 URL，按参考风格生成新图 |
| **自动轮询** | 异步任务自动等待完成，无需手动查进度 |
| **聊天内展示** | 生成结果以 Markdown 图片形式直接显示在 Codex 对话中 |
| **零 Node 配置** | 安装脚本自动下载便携 Node，客户无需单独安装 Node.js |

### 插件提供的 MCP 工具

| 工具 | 用途 |
|------|------|
| `generate_image` | 提交生图任务并自动轮询，返回图片 URL（主要工具） |
| `poll_image_task` | 手动查询任务状态（一般不需要） |
| `list_image_models` | 列出所有可用模型 |

### 支持的模型

| 系列 | 模型 | 适用场景 |
|------|------|----------|
| GPT Image | `gpt-image-2` | 默认，通用出图 |
| GPT Image | `gpt-image-2-vip` | 更高质量 |
| Nano Banana | `nano-banana-fast` | 快速、低成本 |
| Nano Banana | `nano-banana` | 标准质量 |
| Nano Banana Pro | `nano-banana-pro` / `nano-banana-pro-vip` | 高质量，支持 1K/2K/4K |
| Nano Banana Pro | `nano-banana-pro-4k-vip` | 4K 高清 |
| Nano Banana 2 | `nano-banana-2` / `nano-banana-2-cl` / `nano-banana-2-4k-cl` | 新一代模型 |

完整列表见 [`cobabaai-image-plugin/server/model-config.js`](cobabaai-image-plugin/server/model-config.js)。

---

## 环境配置

### 运行环境要求

| 项目 | 要求 |
|------|------|
| **操作系统** | Windows 10 及以上，或 macOS（Apple Silicon / Intel） |
| **Codex** | 已安装 [Codex Desktop](https://openai.com/codex/) |
| **CobabaAi 账号** | 在 [cobabaai.com](https://cobabaai.com/) 注册，并创建 API 令牌 |
| **磁盘空间** | 约 200 MB（便携 Node + 插件依赖，安装脚本自动处理） |
| **Git** | 可选；也可在 GitHub 下载 ZIP 解压使用 |

### 无需单独安装

| 软件 | 说明 |
|------|------|
| **Node.js** | ❌ 不需要。安装脚本会从 [nodejs.org](https://nodejs.org/) 自动下载便携版 Node **v20.18.0** |
| **Python / Java 等** | ❌ 不需要 |
| **系统环境变量** | ❌ 通常不需要手动设置，令牌写入配置文件即可 |

> GitHub 仓库**不含** `packages/node/`（体积过大）。首次运行安装脚本时会联网下载 Node 和 npm 依赖；下载完成后会复制到本机 `~/.codex/packages/node/`，之后运行插件不再依赖系统 PATH 里的 `node` 命令。

### 网络要求

| 阶段 | 是否需要联网 | 访问地址 |
|------|--------------|----------|
| **安装插件** | 需要 | `nodejs.org`（下载 Node）、`registry.npmjs.org`（安装依赖） |
| **配置令牌** | 不需要 | 本地写入配置文件即可 |
| **日常出图** | 需要 | `api.cobabaai.com`（CobabaAi 生图 API） |

若安装阶段无法访问 npm 或 nodejs.org，请检查网络/代理，或联系提供方获取离线安装包。

### 安装后本机目录

安装脚本会在用户目录下创建/更新以下路径（**无需手动创建**）：

| 路径 | 作用 |
|------|------|
| `~/.codex/cobabaai-image.env` | **API 令牌配置文件**（客户需填写） |
| `~/.codex/config.toml` | Codex 主配置，安装脚本自动写入 MCP 段 |
| `~/.codex/packages/node/` | 便携 Node 运行时（安装脚本自动复制） |
| `~/.codex/marketplaces/cobabaai-local/` | 插件 marketplace 与插件文件 |

Windows 下 `~` 即 `%USERPROFILE%`，例如：

```
C:\Users\你的用户名\.codex\cobabaai-image.env
C:\Users\你的用户名\.codex\config.toml
C:\Users\你的用户名\.codex\packages\node\node.exe
C:\Users\你的用户名\.codex\marketplaces\cobabaai-local\plugins\cobabaai-image\
```

macOS / Linux 示例：

```
~/.codex/cobabaai-image.env
~/.codex/config.toml
~/.codex/packages/node/bin/node
~/.codex/marketplaces/cobabaai-local/plugins/cobabaai-image/
```

### 配置文件说明

#### 1. API 令牌文件（必配）

路径：`~/.codex/cobabaai-image.env`

这是**唯一需要客户手动填写**的配置。插件启动时自动读取，**不要**把此文件提交到 GitHub。

```env
# CobabaAi 生图插件配置
COBABAAI_API_KEY=sk-粘贴你的完整令牌
# 可选：未指定模型时的默认值
# COBABAAI_IMAGE_MODEL=gpt-image-2
# 可选：API 地址，一般无需修改
# COBABAAI_BASE_URL=https://api.cobabaai.com
```

配置方式见下方 [获取并配置 API 令牌](#获取并配置-api-令牌)。

#### 2. Codex 配置（自动写入）

路径：`~/.codex/config.toml`

安装脚本会自动追加类似以下内容（**一般无需手改**）：

```toml
[plugins."cobabaai-image@cobabaai-local".mcp_servers.cobabaai-image]
enabled = true
command = "C:\\Users\\你的用户名\\.codex\\packages\\node\\node.exe"
args = ["server/index.js"]
default_tools_approval_mode = "prompt"
tool_timeout_sec = 600
env_vars = ["COBABAAI_API_KEY", "COBABAAI_IMAGE_MODEL"]
```

其中 `command` 指向本机便携 Node；`env_vars` 表示从环境/配置文件转发令牌和默认模型。

#### 3. 环境变量读取优先级

| 优先级 | 来源 | 说明 |
|--------|------|------|
| 1 | `~/.codex/cobabaai-image.env` | **推荐**，用 `配置密钥.bat` 或 `configure-key.sh` 写入 |
| 2 | 系统用户环境变量 | 如已设置 `COBABAAI_API_KEY` |
| 3 | Codex 插件 env 转发 | 由 `config.toml` 的 `env_vars` 声明 |

修改配置后，**重启 Codex 或新开对话** 生效。

### 环境变量一览

| 变量 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `COBABAAI_API_KEY` | **是** | — | CobabaAi API 令牌，以 `sk-` 开头 |
| `COBABAAI_IMAGE_MODEL` | 否 | `gpt-image-2` | 对话未指定模型时使用 |
| `COBABAAI_BASE_URL` | 否 | `https://api.cobabaai.com` | API 基地址，一般无需修改 |
| `CODEX_HOME` | 否 | `~/.codex` | 自定义 Codex 配置目录时使用 |

### 验证环境是否就绪

```bash
# 1. 确认插件已注册
codex plugin list
# 应看到 cobabaai-image@cobabaai-local  → installed, enabled

# 2. 确认令牌文件存在（Windows PowerShell）
Test-Path "$env:USERPROFILE\.codex\cobabaai-image.env"

# 2. 确认令牌文件存在（macOS / Linux）
test -f ~/.codex/cobabaai-image.env && echo OK

# 3. 确认便携 Node 存在（Windows）
Test-Path "$env:USERPROFILE\.codex\packages\node\node.exe"
```

全部通过后，重启 Codex → 新开对话 → 在 **@ 插件** 中启用 **CobabaAi 生图** 即可使用。

---

## 快速开始（3 步）

### 第 1 步：克隆仓库

**Windows（PowerShell）**

```powershell
git clone https://github.com/Colens/codex-image-plugin.git
cd codex-image-plugin
```

**macOS / Linux**

```bash
git clone https://github.com/Colens/codex-image-plugin.git
cd codex-image-plugin
```

> 没有 Git？可在 GitHub 页面点击 **Code → Download ZIP**，解压后进入文件夹。

### 第 2 步：安装插件

**Windows（推荐）**

双击 **`一键安装.bat`**

或在 PowerShell 中执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

**macOS / Linux**

```bash
chmod +x install.sh configure-key.sh scripts/*.sh
./install.sh
```

> macOS 若提示找不到 `codex` 命令：
>
> ```bash
> export CODEX_BIN="/Applications/Codex.app/Contents/Resources/codex"
> ./install.sh
> ```

安装脚本会自动完成：

- 下载或使用便携 Node.js
- 安装 MCP 依赖并构建插件
- 部署到 `~/.codex/marketplaces/cobabaai-local/`
- 注册 Codex 插件 marketplace
- 写入 `~/.codex/config.toml` 中的 MCP 配置

### 第 3 步：配置 API 令牌并启用

1. 按下方 [获取并配置 API 令牌](#获取并配置-api-令牌) 粘贴 `sk-` 密钥
2. **重启 Codex**，新开一个对话
3. 在 **@ 插件** 中确认 **CobabaAi 生图** 已安装并启用

验证安装：

```bash
codex plugin list
```

应看到 `cobabaai-image@cobabaai-local` 状态为 **installed, enabled**。

---

## 获取并配置 API 令牌

### 一、在 CobabaAi 控制台复制令牌

1. 打开 **[https://cobabaai.com/](https://cobabaai.com/)** 并登录账号  
   （没有账号请先注册）

2. 进入 **控制台**（登录后右上角或侧边栏）

3. 打开 **令牌管理**（部分界面显示为「API 密钥」）

4. 点击 **新建令牌** 或 **创建令牌**
   - 可填写备注，例如 `Codex 生图插件`
   - 若有限额/模型权限选项，请确保包含生图相关模型

5. 创建成功后，点击 **复制** 按钮，复制以 **`sk-`** 开头的完整字符串  
   - 示例格式：`sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
   - ⚠️ **令牌只显示一次**，关闭弹窗后无法再次查看，请立即保存
   - ⚠️ **切勿** 将令牌提交到 GitHub、发给他人或写进前端代码

> 官方文档：[CobabaAi API 文档](https://cobabaai.com/docs/zh/guide/api.html) — 创建令牌路径为 **控制台 → 令牌管理**。

### 二、粘贴令牌到本机（三选一）

令牌保存在本地文件，**不会** 上传到 GitHub：

| 平台 | 文件路径 |
|------|----------|
| Windows | `%USERPROFILE%\.codex\cobabaai-image.env` |
| macOS / Linux | `~/.codex/cobabaai-image.env` |

#### 方式 A：配置脚本（推荐）

**Windows：** 双击 **`配置密钥.bat`**

或在 PowerShell 中：

```powershell
powershell -ExecutionPolicy Bypass -File .\configure-key.ps1
```

**macOS / Linux：**

```bash
./configure-key.sh
```

出现提示后，在终端里 **右键粘贴**（或 `Ctrl+V` / `Cmd+V`）刚才复制的 `sk-` 令牌，按回车即可。

#### 方式 B：安装时一并配置

运行 **`一键安装.bat`** 或 **`install.sh`** / **`install.ps1`** 时，脚本会提示粘贴 API 密钥，可直接粘贴，也可留空稍后配置。

#### 方式 C：手动编辑文件

1. 复制仓库中的 `cobabaai-image.env.example`
2. 粘贴到 `%USERPROFILE%\.codex\cobabaai-image.env`（Windows）或 `~/.codex/cobabaai-image.env`（macOS）
3. 将 `sk-你的密钥` 替换为真实令牌：

```env
# CobabaAi 生图插件配置
COBABAAI_API_KEY=sk-粘贴你的完整令牌
# 可选：默认模型，不填则使用 gpt-image-2
# COBABAAI_IMAGE_MODEL=gpt-image-2
```

### 三、生效与更换

- 修改令牌后，**重启 Codex 或新开对话** 生效
- 读取优先级：`cobabaai-image.env` → 系统环境变量 `COBABAAI_API_KEY` → Codex 插件 env 转发
- 更换令牌：重新运行配置脚本，或编辑上述 `.env` 文件

---

## 使用示例

安装并配置令牌后，在 Codex 新对话中直接说：

**基础出图**

```
用 gpt-image-2 生成一张月球上喝咖啡的猫，1024x1024
```

**指定比例与风格**

```
用 nano-banana-fast 画一张赛博朋克风格的猫，16:9
```

**高质量 / 4K**

```
用 nano-banana-pro-vip 生成一张写实风景，4K
```

**图生图（参考图）**

```
用 nano-banana-pro 根据这张参考图生成类似风格：https://example.com/ref.jpg
```

Codex 会调用 `generate_image` 工具，自动提交任务、轮询结果，并在回复中用 Markdown 图片展示。

> **注意：** 返回的图片 CDN 链接约 **2 小时** 有效，请及时右键保存到本地。

---

## 让 Codex 帮你安装

如果你已经在用 Codex，可以直接在新对话里说：

```
请帮我从 GitHub 安装 CobabaAi 生图插件：
https://github.com/Colens/codex-image-plugin.git
安装完成后让我粘贴 API 密钥。
```

Codex 会读取仓库中的 [`AGENTS.md`](AGENTS.md) 并自动执行 clone、安装脚本和密钥配置。

---

## 故障排查

| 问题 | 解决方法 |
|------|----------|
| **未配置令牌 / 401 错误** | 确认 `~/.codex/cobabaai-image.env` 存在且 `COBABAAI_API_KEY=sk-...` 正确 |
| **安装时 npm / Node 下载失败** | 检查能否访问 nodejs.org 和 registry.npmjs.org；必要时配置代理后重跑安装脚本 |
| **@ 插件里看不到 CobabaAi 生图** | 重新运行安装脚本，重启 Codex 并新开对话 |
| **插件列表为空** | 手动执行：`codex plugin marketplace add ~/.codex/marketplaces/cobabaai-local --enable plugins`，再 `codex plugin add cobabaai-image@cobabaai-local --enable plugins` |
| **macOS 找不到 codex 命令** | `export CODEX_BIN="/Applications/Codex.app/Contents/Resources/codex"` 后重试 |
| **生成超时** | nano-banana 系列较慢，插件已设置 600 秒超时，请耐心等待或换 `nano-banana-fast` |
| **图片链接打不开** | CDN 链接有时效，请重新生成或及时保存到本地 |

---

## 目录结构

```
codex-image-plugin/
├── 一键安装.bat              # Windows 一键安装
├── 配置密钥.bat              # Windows 配置 API 令牌
├── install.ps1 / install.sh  # 安装脚本
├── configure-key.ps1 / .sh   # 令牌配置脚本
├── AGENTS.md                 # 供 Codex 自动代装的说明
├── cobabaai-image.env.example
└── cobabaai-image-plugin/    # 插件主体（MCP Server + Skill）
    ├── .codex-plugin/
    ├── server/
    └── skills/
```

---

## 相关链接

- [CobabaAi 官网](https://cobabaai.com/)
- [CobabaAi API 文档](https://cobabaai.com/docs/zh/guide/api.html)
- [Codex 官网](https://openai.com/codex/)

---

## 许可证

使用前请遵守 CobabaAi 平台服务条款。API 令牌属于敏感信息，请妥善保管，不要公开分享。
