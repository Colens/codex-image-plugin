# 分发说明

本插件支持 **两条安装通道**，都不需要客户单独安装 Node.js。

## 通道对比

| | GitHub | 网盘离线包 |
|---|--------|------------|
| **面向用户** | 会用 Git / 会让 Codex 帮忙装 | 普通 Windows 用户 |
| **是否含 Node** | 否（安装时自动下载） | 是（`packages/node/`） |
| **是否需要联网** | 安装时需要（下 Node + npm） | 可完全离线（已预装依赖） |
| **入口** | `install.ps1` / `install.sh` | 解压后 `一键安装.bat` |

---

## 一、GitHub 通道（推荐开发者 / Codex 代装）

### 仓库里有什么

- 插件源码 + 安装脚本
- **不含** `packages/node/`（已在 `.gitignore`）
- 运行安装脚本时会自动从 nodejs.org 下载便携 Node

### 客户 / Codex 安装步骤

**Windows**

```powershell
git clone https://github.com/你的组织/cobabaai-codex-image.git
cd cobabaai-codex-image
.\install.ps1
.\configure-key.ps1
```

**macOS**

```bash
git clone https://github.com/你的组织/cobabaai-codex-image.git
cd cobabaai-codex-image
chmod +x install.sh configure-key.sh
./install.sh
./configure-key.sh
```

### 让 Codex 帮用户装（复制给用户）

```
请帮我从 GitHub 安装 CobabaAi 生图插件：
1. git clone <仓库地址> 到本地
2. Windows 运行 install.ps1，macOS 运行 install.sh（会自动下载 Node，无需我单独装 Node.js）
3. 运行 configure-key 脚本，让我粘贴 CobabaAi API 密钥
4. 重启 Codex 并新开对话
```

也可直接 `@` 本仓库，Codex 读取 `AGENTS.md` 后按步骤执行。

### 维护者发 GitHub Release

只需发布源码 zip，**不必** 打包 Node。说明里写：运行安装脚本即可，无需预装 Node。

---

## 二、网盘通道（推荐普通用户）

### 打离线包（维护者操作）

从 `Codex-Chinese-Setup` 复制已验证的 Node，并预装 npm 依赖：

```powershell
cd D:\githubproject\codex_img
.\scripts\prepare-netdisk-release.ps1 `
  -NodeSource "D:\githubproject\Codex-Chinese-Setup\packages\node"
```

产物在 `dist/cobabaai-codex-image-netdisk-YYYYMMDD.zip`。

### 网盘包结构

```
cobabaai-codex-image-netdisk/
├── packages/node/node.exe      ← 内置 Node，脚本直接调用
├── cobabaai-image-plugin/
│   └── node_modules/           ← 已预装，用户无需 npm
├── 一键安装.bat
├── 配置密钥.bat
├── install.ps1
└── ...
```

### 客户步骤

1. 从网盘下载 zip，解压
2. 双击 **`一键安装.bat`**
3. 双击 **`配置密钥.bat`** 粘贴 sk- 密钥
4. 重启 Codex，新开对话

**全程不需要安装 Node.js，也不需要联网 npm。**

---

## Node 安装到哪里？

无论哪条通道，安装脚本都会：

1. 使用 **`packages/node/`** 里的便携 Node 执行 npm（网盘版）或先下载再执行（GitHub 版）
2. 复制 Node 到 **`~/.codex/packages/node/`**（长期保留）
3. 在 **`~/.codex/config.toml`** 里把 MCP 的 `command` 指向该 Node，运行时不再依赖系统 PATH

---

## 密钥配置

| 平台 | 方式 |
|------|------|
| Windows | `配置密钥.bat` |
| macOS | `./configure-key.sh` |

密钥文件：`~/.codex/cobabaai-image.env`

---

## 建议发布策略

1. **GitHub 公开仓库** — 源码 + 文档 + `AGENTS.md`（给 Codex 代装）
2. **GitHub Releases** — 轻量源码 zip（可选）
3. **网盘** — `prepare-netdisk-release.ps1` 打的 **完整离线 zip**（国内用户主渠道）

网盘说明里写一句：**「本包已内置 Node，无需单独安装 Node.js」**。
