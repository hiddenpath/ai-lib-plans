# ai-protocol 生成式大模型覆盖全链路执行计划（2026-03-06）

> 对应审计：`reviews/audits/AI_PROTOCOL_GENERATIVE_COVERAGE_FULLCHAIN_PLAN_CN.md`  
> 执行窗口：4-6 周  
> 策略：v2 主线 + v1 兼容 + P0 分层推进

## 1. 执行范围

- 协议层：`ai-protocol` Manifest/Schema 扩展
- 模拟层：`ai-protocol-mock` 对应能力与失败注入
- 运行时层：`ai-lib-rust` / `ai-lib-python` / `ai-lib-ts`
- 控制层：`spiderswitch` 运行时能力路由执行演进

## 2. 执行阶段

## Phase A（Week 1-2）：协议与契约固化

- 完成 v2 生成式能力字段扩展定义
- 完成 v1 兼容映射与降级策略
- 形成 P0 provider 能力矩阵

## Phase B（Week 2-3）：mock 对齐与合规测试骨架

- 扩展 `ai-protocol-mock` P0 provider 多模态行为
- 建立 compliance-first 场景矩阵
- 覆盖 sync/stream/async + 失败注入

## Phase C（Week 3-5）：三运行时适配与一致性收敛

- 三运行时按统一 contract 适配 P0 能力
- 打通跨运行时语义一致性断言
- 修复差异并回写到协议文档

## Phase D（Week 5-6）：spiderswitch 跟进与发布准备

- spiderswitch 接入新的 capability routing 信号
- 保持策略上移，不内置业务决策
- 完成 release-ready 检查（回滚演练、文档同步、验收记录）

## 3. 依赖关系（任务级）

- 主任务链：PT-014 -> PT-015 -> PT-016 -> PT-017 -> PT-018
- 下游依赖：
  - 运行时适配依赖 mock 与协议契约稳定
  - spiderswitch 演进依赖运行时 capability contract 输出稳定

## 4. 关键阻塞与缓解

- 阻塞：Provider 文档变动快  
  缓解：增加证据日期与来源追踪
- 阻塞：跨运行时语义不一致  
  缓解：compliance-first 与一致性门禁前置
- 阻塞：上线风险不可回滚  
  缓解：feature flag + rollback drill

## 5. 本轮计划产物

- 审计报告（已产出）
- 全链路执行计划（本文件）
- PT-014~PT-018 任务卡（可直接执行）
- MEMORY 约束追加

