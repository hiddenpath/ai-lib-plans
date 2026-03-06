# spiderswitch 运行时路由策略报告（项目跟踪版）

> 来源：`reviews/audits/SPIDERSWITCH_RUNTIME_ROUTING_REPORT_CN.md`  
> 日期：2026-03-06  
> 状态：draft（待转任务）

## 1. 本次共识

1. `spiderswitch` 只提供运行时路由能力，不内置复杂策略引擎  
2. 策略由上层应用制定，`spiderswitch` 负责执行与状态回传  
3. 运行时扩展目标不局限 Python/Rust/TS，应面向 Go/WASM 等未来适配  
4. 路由核心需求是大模型能力分发，同时评估运行时能力

## 2. 关键决策

- **职责边界**：
  - spiderswitch：runtime registry、runtime capability 暴露、路由执行、状态观测
  - 上层应用：策略制定、权重决策、业务规则、成本预算
- **演进方向**：
  - 先统一抽象，再扩展实现
  - 迁移优先级由场景需求决定，不强制一步到位迁移到单一语言

## 3. 架构落地点（建议）

### 3.1 runtime-neutral 能力模型

- `runtime_id`（python/rust/ts/go/wasm）
- `model_capabilities`（tools/vision/audio/streaming/...）
- `runtime_capabilities`（concurrency/retry/circuit_breaker/proxy/hot_reload/...）
- `operational_metrics`（latency/error_rate/cold_start/recovery_time）

### 3.2 runtime adapter 契约

- `list_models(filters)`
- `switch_model(target)`
- `status()`
- `close()/reset()`

### 3.3 路由模式

- 显式指定 runtime（调试/运维）
- 上层策略下发 runtime 选择结果（主模式）
- 默认回退链（仅兜底）

## 4. 场景收益与代价

### 收益

- 按能力分发，减少能力不匹配失败
- 迁移期可灰度对比，降低发布风险
- 为多语言 runtime 演进提供统一入口

### 代价

- 多 runtime 并行带来观测和调试复杂度上升
- 需要跨运行时契约测试与一致性治理
- 不恰当自动路由会产生抖动和资源浪费

## 5. 近期执行建议（转任务前）

1. 定义 `runtime capability schema` 草案（含 Go/WASM 保留字段）
2. 设计 `runtime registry/resolver` 最小接口
3. 补齐“同输入同语义输出”的跨运行时契约测试框架
4. 明确“禁止策略下沉到 spiderswitch 内部”的代码审查准则

## 6. 下一步

- 将本报告拆解为项目任务（`active/projects/spiderswitch/tasks/`）：
  - 任务 A：runtime capability schema
  - 任务 B：runtime adapter SPI
  - 任务 C：routing execution API
  - 任务 D：cross-runtime contract tests

