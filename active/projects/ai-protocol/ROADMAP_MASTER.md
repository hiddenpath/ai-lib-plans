# ai-protocol 研发总计划（ai-lib-plans 主控）

> 状态：生效中  
> 生效日期：2026-02-28  
> 维护仓库：`ai-lib-plans`（唯一计划主源）

## 1. 目的与范围

从本文件起，`ai-lib-plans` 作为 ai-lib 生态（`ai-protocol` / `ai-lib-rust` / `ai-lib-python` / `ai-lib-ts` / `ai-protocol-mock`）的唯一计划主控仓库。  
历史计划文档仅作为“输入与审计依据”，不再作为执行主入口。

## 2. 历史计划整合来源

- 主要来源：`AI-Protocol项目研发计划_v4.md`（原位于 `d:/ai-protocol/`）
- 整合方式：
  - 目标、阶段、里程碑抽取为可执行任务（`active/projects/*/tasks/*.yaml`）
  - 已完成事项回写到任务 `completion_notes`
  - 持久决策沉淀到 `MEMORY.md`

## 3. 执行规则（强制）

1. 新增/变更工作必须先落任务（YAML）再实施。  
2. 跨仓库工作必须拆分为“主任务 + 下游对齐任务”，并写依赖。  
3. 发布前必须完成：任务关闭、README/CHANGELOG 对齐、release notes。  
4. 若历史计划与现任务冲突，以 `ai-lib-plans` 活跃任务为准。  

## 4. 当前阶段映射（从 v4 迁移后）

- 阶段三（已完成）：作为历史基线，不再直接编辑原 v4 文档
- 阶段四（进行中）：通过 `active/projects/*/tasks/` 持续推进
- 新增工作流：
  - `PT-006`：v2 schema/CI 修复（已完成）
  - `PT-007`：mock 与下游影响评估（已完成）
  - `PT-008`：mock 发版 + 三运行时冒烟（已完成）
  - `PT-009`：benchmark 变更合法化 + 运行时阻塞修复（已完成）
  - `PT-010`：v4 路线图治理整合与运行时发布列车（已完成）
  - `PT-011`：多模态文档方法学与证据分级加固（已完成）
  - `PT-012`：compliance-first 多模态验证矩阵与跨运行时门禁（已完成）
  - `PT-013`：多模态发布/回滚/开关策略治理（已完成）
  - `PT-014`：v2 生成式多模态 Manifest 扩展 + v1 兼容层（已完成）
  - `PT-015`：ai-protocol-mock P0 provider 多模态行为对齐（已完成）
  - `PT-016`：三运行时 P0 适配与语义一致性收敛（已完成）
  - `PT-017`：spiderswitch 能力路由执行跟进（已完成）
  - `PT-018`：P0 发布列车与回滚就绪治理（已完成）
  - `PT-019`：P1 provider 扩展波次规划（已完成）
  - `PT-020`：P1 视频生成/编辑语义契约定义（已完成）
  - `PT-021`：P1 三运行时性能与稳定性加固计划（已完成）
  - `PT-022`：P2 Go/WASM adapter 可行性与契约定义（已完成）
  - `PT-023`：P2 漂移检测与周期对账自动化方案（已完成）
  - `PT-024`：P1/P2 一体化发布门禁与回滚演练体系（已完成）
  - `PT-025`：Wave-2 跨仓 manifest 消费门禁常态化（已完成）
  - `PT-026`：load 类 compliance 从 skip 到强校验（已完成）
  - `PT-027`：三运行时 V2 manifest 结构兼容统一（已完成）
  - `PT-028`：mock 视频生命周期语义扩展（已完成）
  - `PT-029`：drift/release-gate 接入 CI report-first（已完成）
  - `PT-030`：Wave-2 RC 评审与回滚演练闭环（已完成）
  - `PT-031`：retry_decision compliance 三运行时执行激活（已完成）
  - `PT-032`：message/stream/request compliance 三运行时全量执行激活（已完成）
  - `PT-033`：cross-repo compliance matrix gate 与治理集成（已完成）
  - `PT-034`：fullchain governance gate 编排入口（已完成）
  - `PT-035`：required gate 基线晋级与执行证据固化（已完成）
  - `PT-036`：P1 provider 扩展 wave-1（已完成）
  - `PT-037`：视频生成/编辑契约三层对齐（已完成）
  - `PT-038`：spiderswitch 运行时路由契约测试（已完成）
  - `PT-039`：v0.9.x RC 门禁评审与发布列车（已完成）

### Wave-3C：报告治理与 IOSPC 边界（PT-040~PT-050 已完成）

  - `PT-040`：报告治理模板包采纳与 F/D 基线建立（已完成）
  - `PT-041`：F 层事实报告重构与证据加固（已完成）
  - `PT-042`：D 层设计报告重构与验证计划（已完成）
  - `PT-043`：report-evidence-gate report-only 试点（已完成）
  - `PT-044`：IOS 跨运行时 required gate 晋级（已完成）
  - `PT-045`：IOS 边界 fixture 与反例扩展（已完成）
  - `PT-046`：Process/Contract 阶段就绪设计与回滚（已完成）
  - `PT-047`：IOSPC 阶段 schema 与运行时 compliance 试点（已完成）
  - `PT-048`：IOSPC required gate 演练与回滚通道（已完成）
  - `PT-049`：IOSPC fail-fast required vs report-only 演练（已完成）
  - `PT-050`：fullchain 回滚演练集成（已完成）

### Wave-3D：四运行时治理与公共引用迁移（PT-051~PT-053 已完成）

  - `PT-051`：四运行时 manifest loading 矩阵 Go 纳入（已完成）
  - `PT-052`：公开 manifest 引用迁移至 ailib-official（已完成）
  - `PT-053`：公共 URL hygiene CI 治理基线（已完成）

### Wave-4：生成式大模型扩容与运行时对齐（PT-054~PT-062 进行中）

> 总体目标：将生成式大模型（LLM）完整纳入协议 schema、四运行时对齐、mock 覆盖，
> 并开启 WASM 运行时演进路径，目标里程碑 v1.0.x。

  - `PT-054`：Plans 与路线图真源对齐（治理基线修复）
  - `PT-055`：MEMORY 四运行时与 Wave-4 事实对齐
  - `PT-056`：ai-protocol 仓库 reports/ 目录治理策略
  - `PT-057`：生成式大模型 Manifest Schema 扩展与运行时支持规划（核心）
  - `PT-058`：四运行时生成式能力语义对齐矩阵（核心）
  - `PT-059`：ai-protocol-mock 生成式模型场景扩展
  - `PT-060`：P1 Provider Wave-2 生成式大模型选型与排期
  - `PT-061`：WASM Runtime Adapter 分阶段演进规划
  - `PT-062`：阶段性门禁评审与 v1.0.x RC 发布列车

### Wave-4B：四运行时生成式适配编码（PT-063~PT-066）

> 前置审计发现所有四运行时均需适配编码以通过 08-generative-capabilities 合规矩阵。

> **2026-03-31**：四运行时「官方库质量门禁」补强已分别推送 PR 分支（`pt-063-{rust,python,ts,go}-hardening` → `hiddenpath/*` 远端）；合并前在 GitHub 上针对 `main` 开 PR。细节与验证命令见 `MEMORY.md`「Four-Runtime Official Library Quality Gates」与各任务 YAML 的 `completion_notes`。

  - `PT-063`：ai-lib-rust 生成式适配（Usage/reasoning_tokens、structured output wiring、thinking stream、feature_flags enforcement、compliance runner）**+ 质量门禁闭环（fmt/clippy/tests/doctest/CI）**
  - `PT-064`：ai-lib-python 生成式适配（Usage、compliance input types、reasoning mapper、feature_flags、MCP naming）**+ CI/docs/mypy 门禁补强（已完成）**
  - `PT-065`：ai-lib-ts 生成式适配（Usage、ThinkingDelta pipeline、feature_flags parsing、ToolCallAccumulator、error_classification wiring）**进行中；已推送 TS 质量门禁与协议测试加固分支**
  - `PT-066`：ai-lib-go 生成式适配（Usage struct、SSE thinking、ResponseFormat wiring、ToolCall streaming、compliance runner）**进行中；已落地 Usage/Chat 载荷/loader/CI，其余项仍在本任务内跟踪**

### Wave-5：执行层/策略层分离与 v1.0 发布（PT-067~PT-073 规划中）

> **2026-04-01**：基于 Paper1《The AI Execution Layer》§3 最小性约束，将四运行时拆为
> **ai-lib-core（最小执行层）** + **ai-lib-contact（策略层）** 两个物理包，并在 core-only
> 基础上实现 WASM 构建，作为 v1.0.0 发布的核心条件。
> 详细方案见 `WAVE5_EP_SEPARATION_AND_V1_PLAN_2026-04-01.md`。

  - `PT-067`：E/P 边界合同定义与跨运行时对齐（ExecutionResult/ExecutionMetadata 四语言 + 模块分类矩阵 + 依赖方向验证）
  - `PT-068`：ai-lib-rust core/contact crate 拆分（Cargo workspace 三 crate + WASM 编译门禁）
  - `PT-069`：ai-lib-python core/contact 包拆分（extras 或独立包 + core-only 合规通过）
  - `PT-070`：ai-lib-ts core/contact 包拆分（@ailib/core + @ailib/contact + bundle size 门禁）
  - `PT-071`：ai-lib-go core 验证（已近最小，补齐 ExecutionMetadata 合同）
  - `PT-072`：WASM 从 core-only 构建（PT-061 Phase 1 执行，6 导出函数 + wasmtime 合规）
  - `PT-073`：core-only 合规证明 + v1.0.0 RC 门禁（四语言 + WASM + 迁移文档 + 发布列车；pre-1.0 允许破坏性布局）

## 5. 维护约定

- 本文件仅维护“治理规则 + 阶段映射”，不记录日常执行细节。
- 执行细节统一写入对应任务文件与 standup。
- 若需要引入新主计划版本（v5+），必须先在 `ai-lib-plans` 建迁移任务，再导入。
