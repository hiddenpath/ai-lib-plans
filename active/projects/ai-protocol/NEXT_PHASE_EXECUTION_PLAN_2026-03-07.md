# 下一阶段执行计划（P1/P2 Wave-2，2026-03-08 ~ 2026-04-05）

## 1. 阶段目标

在 `v0.8.0 / v0.9.0 / v0.8.0 / v0.5.0` 发布基线之上，推进 P1/P2 Wave-2：

1. 将“最新 V2 manifest 消费与利用”从专项验证提升为常态化门禁。
2. 完成三运行时在关键生成式能力上的语义补齐与契约统一。
3. 将 drift/release-gate 从“可运行脚本”升级为“可持续治理流程”。

## 2. 执行窗口与节奏

- 周期：4 周（2026-03-08 至 2026-04-05）
- 节奏：Mon/Wed/Fri 监督节奏（沿用 PT-012/PT-013）
- 每周里程碑：
  - Week-1：门禁与基线固化
  - Week-2：三运行时语义补齐
  - Week-3：CI 集成与回滚演练
  - Week-4：Release Candidate 评估与冻结

## 3. 任务波次（PT-025 ~ PT-030）

### Wave-2A：门禁固化

- `PT-025`：跨仓 manifest 消费验证门禁常态化
- `PT-026`：compliance 加载类（load-*）从 skip 升级为强校验执行

### Wave-2B：语义补齐

- `PT-027`：三运行时 V2 manifest 结构兼容统一（endpoint/endpoints、streaming、multimodal）
- `PT-028`：mock 视频生成生命周期扩展（含终态一致性与异常路径）

### Wave-2C：治理集成

- `PT-029`：drift/release-gate 接入 CI report-first 流水线并沉淀周报
- `PT-030`：P1/P2 Wave-2 RC 发布评审与回滚演练闭环

### Wave-3A（已完成）

- `PT-031`：`retry_decision` compliance 在 Python/Rust/TS 三运行时执行激活
- `PT-032`：message/stream/request compliance 矩阵在三运行时全量执行激活
- `PT-033`：跨仓 compliance matrix gate 脚本与治理流水线接入
- `PT-034`：fullchain governance gate 一键编排入口

### Wave-3B（当前执行）

- `PT-035`：fullchain 门禁从 report-first 向 required 基线晋级（进行中）
- `PT-036`：P1 provider 扩展 wave-1（manifest/mock/三运行时消费）
- `PT-037`：视频生成/编辑契约在 protocol/mock/runtime 三层对齐
- `PT-038`：spiderswitch 运行时能力路由契约测试补齐
- `PT-039`：v0.9.x RC 门禁评审与跨仓发布列车闭环

## 4. 交付物定义

- 计划与治理文档：
  - Wave-2 执行板、周报、风险看板、RC 评审记录
- 代码与测试：
  - 三运行时兼容性补丁
  - mock 行为增强
  - compliance/集成测试新增用例
- 发布治理：
  - CI 中 drift/gate 报告归档
  - rollback drill 记录与触发阈值验证

## 5. 验收口径（阶段级）

1. 三运行时对最新 V2 manifest 的消费/利用回归用例全部通过且纳入常态测试。
2. `drift:check` 与 `release:gate` 在 CI 中可追踪、可审计、可回放。
3. 至少完成 1 次演练级回滚 drill，形成可执行证据。
4. `ailib.info` 对外文档持续与发布矩阵同频更新。

## 6. 风险与回滚

### 主要风险

- 多仓并行推进导致语义漂移复发
- CI 门禁收紧导致迭代吞吐下降
- mock 行为增强与下游测试假设不一致

### 回滚策略

- Gate 采用分级：report-only -> warning -> required（逐级升级）
- 语义补丁按仓独立提交，支持逐仓回退
- mock 新行为默认 feature flag 保护

## 7. 监督与升级规则

- 任一 `critical drift` 超过 48 小时未闭环：暂停 Release Promotion。
- 任一运行时语义回归触发：冻结该能力链路进入修复优先队列。
- 每周五固定输出：进度、风险、阻塞、下周计划四栏报告。

## 8. 执行状态（实时）

- `PT-025`: `completed`（统一门禁脚本、runbook、required 基线证据已闭环）
- `PT-026`: `completed`（load-* 在 Python/Rust/TS 三运行时全部进入强校验执行路径）
- `PT-027`: `completed`（三运行时 V2 manifest shape 兼容矩阵已对齐并通过回归）
- `PT-028`: `completed`（mock 视频生命周期终态语义扩展 + 失败路径注入 + 测试/文档闭环）
- `PT-029`: `completed`（drift/release-gate report-first CI 接入 + 报告归档）
- `PT-030`: `completed`（RC 评审包 + 回滚演练记录 + go/hold/no-go 输入）
- `PT-031`: `completed`（retry_decision 跨运行时执行激活并通过）
- `PT-032`: `completed`（message/stream/request compliance 全量激活并通过）
- `PT-033`: `completed`（cross-repo compliance gate 与报告归档落地）
- `PT-034`: `completed`（fullchain gate 编排落地并通过 required 基线）
- `PT-035`: `completed`（required-mode 推广口径/阈值边界/回退策略已落地并完成验证）
- `PT-036`: `completed`（Wave-1 provider onboarding：manifest/mock/三运行时消费对齐已闭环）
- `PT-037`: `completed`（视频契约断言已在 Rust/Python/TS 消费路径闭环）
- `PT-038`: `completed`（spiderswitch 路由契约测试与文档边界已闭环）
- `PT-039`: `pending`

