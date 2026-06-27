# 内置 Node.js（网盘版 / 离线包）

本目录用于存放 **便携版 Node.js**，结构与 `Codex-Chinese-Setup/packages/node` 一致：

```
packages/node/
├── node.exe          # Windows
├── npm.cmd
└── bin/node          # macOS / Linux（若打包 mac 版）
```

## GitHub 仓库

**不要** 把 `packages/node/` 提交到 Git。GitHub 用户运行 `install.ps1` / `install.sh` 时会 **自动下载** Node。

## 网盘离线包

打网盘包前，从 `Codex-Chinese-Setup` 复制 Node，或运行：

```powershell
.\scripts\prepare-netdisk-release.ps1 -NodeSource "D:\githubproject\Codex-Chinese-Setup\packages\node"
```

然后上传 `dist/` 下的 zip 到网盘。
