# PT-073d — CHANGELOG / 迁移文档差距审计

> **日期**: 2026-06-29  
> **任务**: [PT-073d-migration-changelog.yaml](./tasks/PT-073d-migration-changelog.yaml)  
> **门控**: WAVE5 §4

## 对照结果

| 运行时 | CHANGELOG E/P 段落 | 迁移路径说明 | 缺口 |
|--------|-------------------|--------------|------|
| **Rust** | ✅ 0.9.x — workspace split, `ai-lib-core` / `ai-lib-contact` / facade | README + CHANGELOG breaking paths | 可选：v1.0 前统一「Migration」小节标题 |
| **Python** | 🟡 0.8.x — Wave-5 boundary note, `contact` extra | 缺显式 import 对照表（`ai_lib_python` vs contact 模块列表） | **R2** |
| **TypeScript** | 🟡 0.5.x — `/core` `/contact` subpaths | 缺从根 import 迁移示例 | **R3** |
| **Go** | ✅ 0.2.x — `pkg/contact` breaking move | 已列 breaking import | 可选：与 `pkg/ailib` 能力矩阵表 |

## 建议 R2/R3 最小交付

1. **Python** `CHANGELOG.md`：增加 `## Migration (E/P separation)` — core-only install、`contact` extra、禁止 import 列表指针 `ep-boundary/module-matrix.yaml`。
2. **TypeScript** `CHANGELOG.md`：增加 migration 表 — `@ailib-official/ai-lib-ts` → `/core` / `/contact`。
3. **WAVE5 §4**：四仓库均有可追溯段落后勾选。

## 非阻塞

- spiderswitch downstream — **已从 v1.0 门控移除**（2026-06-29）：历史 WAVE5 示例消费者；现以 Prism/eos/Vela 为 P 层产品路线。
