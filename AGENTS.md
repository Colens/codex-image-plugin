# Codex Agent 安装指南

当用户要求从 GitHub 安装 **CobabaAi 生图** Codex 插件时，按以下步骤执行。

## 前提

- 用户已安装 Codex Desktop
- **不需要** 用户预装 Node.js（安装脚本会自动下载或使用内置 Node）

## Windows

```powershell
git clone <仓库地址>
cd codex_img
powershell -ExecutionPolicy Bypass -File .\install.ps1
powershell -ExecutionPolicy Bypass -File .\configure-key.ps1
```

然后提示用户：**重启 Codex，新开对话**，在 @ 插件 中确认 **CobabaAi 生图** 已启用。

## macOS

```bash
git clone <仓库地址>
cd codex_img
chmod +x install.sh configure-key.sh scripts/*.sh
./install.sh
./configure-key.sh
```

若找不到 `codex` 命令：

```bash
export CODEX_BIN="/Applications/Codex.app/Contents/Resources/codex"
./install.sh
```

## 密钥

- 文件位置：`~/.codex/cobabaai-image.env`
- 内容：`COBABAAI_API_KEY=sk-...`
- 从 https://cobabaai.com/ 控制台获取

## 验证

```bash
codex plugin list
```

应看到 `cobabaai-image@cobabaai-local` 为 `installed, enabled`。

## 测试

在新对话中说：

```
用 gpt-image-2 生成一张月球上喝咖啡的猫
```

## 故障

- 插件列表看不到：重新运行 install 脚本，重启 Codex
- 未配置密钥：运行 configure-key 脚本
- 详细说明见 `README.md`
