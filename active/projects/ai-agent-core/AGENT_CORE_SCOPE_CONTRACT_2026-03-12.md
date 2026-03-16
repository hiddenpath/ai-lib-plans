# ai-agent-core 边界与接口契约（冻结稿）

日期：2026-03-12  
状态：frozen-v1

## 1. 目标

在不破坏现有 `spiderswitch` MCP Server 产品边界的前提下，新增 `ai-agent-core` 作为任务编排与策略决策核心。

## 2. 四仓职责边界（冻结）

### `ai-agent-core`（新增）
- 职责：任务接入（intake）、规划（planner）、策略路由（router）、执行编排（executor）、观测反馈（observe）。
- 非职责：不承载 provider 适配细节；不复制 runtime 协议实现；不替代 spiderswitch 执行面。

### `spiderswitch`
- 职责：MCP 执行网关、runtime 切换执行、状态查询、错误治理。
- 非职责：不做业务策略决策（成本/租户/优先级策略）。

### `ai-lib-*`（python/rust/ts/go）
- 职责：协议驱动 runtime 能力实现（请求构造、能力映射、弹性与回退等）。
- 非职责：不承载 agent 任务编排状态机。

### `ai-protocol`
- 职责：协议规范、schema、provider manifest。
- 非职责：不承载运行时或编排业务逻辑。

## 3. 对接契约（冻结）

`ai-agent-core` 与 `spiderswitch` 通过 MCP 工具语义对接，v1 固定如下：

- `list_models(filter_provider?, filter_capability?, require_api_key?, runtime_id?)`
- `switch_model(model, api_key?, base_url?, runtime_id?)`
- `get_status(runtime_id?)`
- `exit_switcher(runtime_id?, scope?)`

约束：
- 编排策略仅产生“决策结果”（runtime_id + model + constraints）。
- 执行动作统一由 `spiderswitch` 工具完成。
- `ai-agent-core` 不依赖 `spiderswitch` 内部私有函数签名。

## 4. 数据与状态边界

- 任务状态机归 `ai-agent-core` 管理（planned/routed/executing/succeeded/failed...）。
- 模型连接态归 `spiderswitch` 管理（runtime_id/runtime_epoch/connection_epoch）。
- 长期记忆与任务执行记录存储在 `ai-agent-core`（可插拔）。

## 5. 演进规则

- 任何超出上述边界的改动，需先更新本契约并在 `ai-lib-plans` 立项。
- 变更报告需标记规则引用：`[ARCH-001] [ARCH-003] [DOC-001] [DOC-002]`。
