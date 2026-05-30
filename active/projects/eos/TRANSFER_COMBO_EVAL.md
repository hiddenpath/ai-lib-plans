# transfer.md 组合任务 — 严格评估与执行切片（2026-05-29）

> 来源：`Y:\transfer.md`（Sisyphus 交接 + §7 补充分析）
> 关联：EOS-ARCH-R2、PT-075、hiddenpath/eos PR #3

## 评估结论（合理性）

| 主张 | 判定 | 说明 |
|------|------|------|
| EOS PR #3 已合并（capacity + R7） | ✅ 正确 | `1271ef0` / PR #3 merged |
| v2 schema 已有 `availability.regions` | ✅ 正确 | 全 12 v2 provider 已标注（PR #2+#3） |
| R2 = 填充 region + approval_id | ✅ 完成 | PR #2 Phase 0–1 + PR #3 Phase 3 backfill |
| 立即强行对齐 Eos model ID ↔ v2 manifest | ❌ 过度 | §7.4：合规路由仅需 provider 级 region |
| P2-R1 SessionMirror 可并行 | ✅ 正确 | PR #4 已合并；strategy 扩展 PR #5 待合并 |

## 执行切片（状态）

### PR-1 — ai-protocol（**已合并** `e042e2b`）

- PR：https://github.com/ailib-official/ai-protocol/pull/2
- Phase 0–1：availability.regions、approval_ids、NVIDIA/Groq、OpenAI/Google capacity

### PR-2 — ai-protocol（**已合并** `d295ff0`）

- PR：https://github.com/ailib-official/ai-protocol/pull/3
- Phase 3：anthropic/cohere/jina/qwen/zhipu/moonshot/doubao availability backfill

### PR-3 — ai-protocol（**已提交** PT-075-R1）

- PR：https://github.com/ailib-official/ai-protocol/pull/4
- `metadata-model-entry.json` 类型化 capacity 字段

### eos SessionMirror

- PR #4 `3a0c713` — R1 基础 ✅
- PR #5 — strategy 扩展点（`assembleMessages(maxTokens, strategy?)`）待合并

### eos manifest 消费（Phase 2+，可选）

- 从 manifest 读取 provider/model（替换 `config.rs` 硬编码）
- **依赖**：PT-075 + 产品决策

## Plans 回填

- `EOS-P0-R7` → completed（eos PR #3）
- `EOS-ARCH-R2` → completed（ai-protocol PR #2+#3）
- `EOS-P2-R3` → completed（eos PR #3 capacity）
- `EOS-P2-R1` → completed（PR #4）；strategy follow-up PR #5
- `EOS-P2-R2/R4` → pending（ALR-P2-001 未实现，勿误标 completed）
- `PT-075-R1` → in_progress（ai-protocol PR 待合并）
