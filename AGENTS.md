# Codex Agent 安装指南

当用户要求安装 **CobabaAi 生图** Codex 插件时，按以下步骤执行。

## 前提

- 用户已安装 Codex Desktop
- **不需要** 用户预装 Node.js（安装脚本会自动下载或使用内置 Node）
- 仓库：https://github.com/Colens/codex-image-plugin（Public，专有许可，见 `LICENSE`）

## 推荐：一键安装（Windows / macOS）

**Windows**

```powershell
git clone https://github.com/Colens/codex-image-plugin.git
cd codex-image-plugin
powershell -ExecutionPolicy Bypass -File .\install.ps1
powershell -ExecutionPolicy Bypass -File .\configure-key.ps1
```

或双击 `一键安装.bat` → `配置密钥.bat`。

**macOS**

```bash
git clone https://github.com/Colens/codex-image-plugin.git
cd codex-image-plugin
chmod +x install.sh configure-key.sh scripts/*.sh
./install.sh
./configure-key.sh
```

若找不到 `codex` 命令：

```bash
export CODEX_BIN="/Applications/Codex.app/Contents/Resources/codex"
./install.sh
```

## 可选：GitHub 插件市场

安装脚本会自动执行 `codex plugin marketplace add Colens/codex-image-plugin`。也可手动：

```bash
codex plugin marketplace add Colens/codex-image-plugin --enable plugins
codex plugin add cobabaai-image@cobabaai --enable plugins
```

**重要：** 市场安装只注册插件元数据；**仍须运行 `install.ps1` / `install.sh`** 以安装 npm 依赖、便携 Node 和 `config.toml` MCP 段。仓库不含 `node_modules`。

## 密钥

- 文件：`~/.codex/cobabaai-image.env`
- 内容：`COBABAAI_API_KEY=sk-...`
- 从 https://cobabaai.com/ 控制台获取

## 验证

```bash
codex plugin list
```

应看到 `cobabaai-image@cobabaai` 为 `installed, enabled`。

## 测试

**单张：**

```
用 gpt-image-2 画一只在月球上喝咖啡的猫，1280x1280
```

**批量（2～10 张，一次并行）：**

```
用 nano-banana-2 并行生成 5 张不同风格的赛博朋克城市，1280x1280
```

批量须调用 `generate_images_batch`，禁止循环 10 次 `generate_image`。

**无需单独配置 Skill**——插件自带 Skill；在 @ 插件 中启用 **CobabaAi 生图** 即可。

## 故障

- 插件列表看不到：重跑 install 脚本，完全重启 Codex
- 未配置密钥：运行 configure-key 脚本
- **工具未暴露 / 生图失败**：`doctor.ps1`（Windows）或 `./doctor.sh`（macOS），再重跑 install，**完全重启** Codex 并新开对话
- **AI 空转、弹权限读 .env**：不要读密钥文件；重启 → 新对话 → @ CobabaAi 生图 → 直接说「画…」
- 详细说明见 `README.md`
