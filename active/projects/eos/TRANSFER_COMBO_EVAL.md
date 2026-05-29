# transfer.md 组合任务 — 严格评估与执行切片（2026-05-29）

> 来源：`Y:\transfer.md`（Sisyphus 交接 + §7 补充分析）
> 关联：EOS-ARCH-R2、PT-075、hiddenpath/eos PR #3

## 评估结论（合理性）

| 主张 | 判定 | 说明 |
|------|------|------|
| EOS PR #3 已合并（capacity + R7） | ✅ 正确 | `1271ef0` / PR #3 merged |
| v2 schema 已有 `availability.regions` | ✅ 正确 | 但 **0/10 v2 YAML 曾使用** |
| R2 = 填充 region + approval_id | ⚠️ 部分正确 | schema 已有 regions enum；缺 `approval_ids`（本 PR 补） |
| 立即强行对齐 Eos model ID ↔ v2 manifest | ❌ 过度 | §7.4 正确：合规路由仅需 provider 级 region；ID 对齐属 Phase 2 manifest 消费 |
| §4.2 Groq 模型列表 | ⚠️ 需修正 | 应以 **Eos 运营模型**为准（`llama-3.1-8b-instant`），非 transfer 表中的 mixtral/3.2 系列 |
| §4.2 Google preview ID | ⚠️ 需修正 | 用 Eos 实际暴露的 `gemini-2.5-*` / `gemini-3.1-flash-lite-preview` |
| model 级 region 双层覆盖 | ❌ 本阶段不做 | §7.5：无业务驱动，先 provider 级 |
| Phase 1–3 可完全并行 | ❌ 需调整 | §7.6：新建 provider 必须先存在再标注 region |
| P2-R1 SessionMirror 可并行 | ✅ 正确 | 不阻塞 ARCH；独立 track |

## 执行切片（已启动）

### PR-1 — ai-protocol（**已提交**）

- 仓库：`ailib-official/ai-protocol`
- PR：https://github.com/ailib-official/ai-protocol/pull/2
- 范围：Phase 0–1
  - `approval_ids` on `availability.json`
  - DeepSeek reference `availability` (cn+global)
  - NVIDIA + Groq v2 providers（Eos 模型 + capacity）
  - OpenAI / Google global availability + Eos 模型 capacity 条目
  - 修复 v2 `parameter_mappings` schema 违规（validate 52/52）

### PR-2 — ai-protocol（待 PR-1 合并）

- Phase 3 剩余：qwen / zhipu / moonshot / doubao / anthropic / cohere / jina 补 `availability.regions`
- cn provider 示例：`approval_ids.cn`（需真实备案号来源，禁止编造）
- PT-075-R1 正式 schema（`metadata.models` 类型化）可与此 PR 或独立 PR

### PR-3 — eos（可选，Phase 2+）

- 从 manifest 读取 provider/model（替换 `config.rs` 硬编码）
- **依赖**：PT-075 + ARCH R2 合并 + 产品决策

### 并行 track — EOS-P2-R1

- SessionMirror 内存版（`static/js/session_mirror.js`）
- 不依赖 ai-protocol PR

## Plans 回填

- `EOS-P0-R7` → completed（PR #3）
- `EOS-ARCH-R2` → in_progress（PR #2 部分交付）
- `PT-075` → 仍 pending；本 combo 在 metadata.models 填 capacity，**不替代** R1 正式 schema
