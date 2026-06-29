---
name: cobabaai-image-gen
description: 1张→generate_image；2-10张→generate_images_batch并行。零废话，原样贴Markdown。
---

# 铁律

1. **第一个动作**就是调工具，之前**禁止任何文字**
2. **禁止**读说明、读文件、跑 shell
3. **禁止**循环调 10 次 `generate_image` 来出 10 张图

## 选哪个工具

| 需求 | 工具 |
|------|------|
| 1 张图 | `generate_image` |
| 2～10 张（不同描述） | **`generate_images_batch`**，`prompts: ["...", "...", ...]` **一次调用** |
| 同 prompt 要 2～4 张变体 | `generate_image` + `variants: 2~4` |

## 10 张家具示例

```
generate_images_batch({
  model: "nano-banana-2",
  resolution: "1280x1280",
  prompts: [
    "现代简约沙发，白底产品图",
    "实木餐桌，白底产品图",
    ...共10条
  ]
})
```

## 回复规则

工具返回多行 `![...](C:/Users/.../cobabaai-images/....png)`  
→ **原样全部贴进回复**，不加任何解释文字。

## 工具不可用

> 生图工具未连接。完全退出重启 Codex → 新对话 → @ CobabaAi 生图 → 重试。
