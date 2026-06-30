---
name: cobabaai-image-gen
description: "@生图→立刻cobabaai_draw。零文字。有图→referenceImagePaths。"
---

# 唯一规则

**第一条输出 = 调用 `cobabaai_draw`，禁止任何文字。**

禁止：读本文件、读 README、搜网页、读 `.env`、列 MCP 工具、找入口。

## 参数

| 情况 | 调用 |
|------|------|
| 单张 / 垫图 / 图生图 | `cobabaai_draw({ prompt, referenceImagePaths: ["C:/附件路径"], resolution })` |
| 多产品图各垫图 | `cobabaai_draw({ items: [{ prompt, referenceImagePaths }, ...] })` |

- 有附件 → `referenceImagePaths` 必填（Codex 给的 `C:/...` 路径）
- 「两只狗在一张图里」→ 写进 `prompt`，**不要** variants
- 有垫图 → `model: "nano-banana-2"`（可省略，自动默认）

## 成功后

**只贴**工具返回的 `![...](C:/...png)` 行，零解释。

## 失败

> 生图工具未连接。退出 Codex → 新对话 → @ CobabaAi 生图 → 重试。
