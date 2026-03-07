# AI-Protocol 生成式大模型覆盖全链路规划审计报告（CN）

**日期**: 2026-03-06  
**范围**: `ai-protocol` / `ai-protocol-mock` / `ai-lib-rust` / `ai-lib-python` / `ai-lib-ts` / `spiderswitch`  
**约束输入**:
- Manifest 路径：`v2-primary`（带 v1 兼容层）
- 覆盖策略：`P0 分层推进`
- 时间窗口：`4-6 周`
- P0 优先对象：`OpenAI/Anthropic/Gemini` + `DeepSeek/Qwen/Doubao` + `音频/视频生成链路`

---

## 1. 目标定义

在 4-6 周内建立“可执行、可验证、可回滚”的生成式大模型覆盖主线，覆盖：

1. `ai-protocol` Manifest 能力扩展（v2 主线）
2. `ai-protocol-mock` 行为对齐与合规验证支撑
3. 三运行时（Rust/Python/TS）适配与一致性校验
4. `spiderswitch` 跟进演进（能力路由执行层）

---

## 2. 核心原则（门禁）

- [ARCH-001] 协议驱动：禁止 runtime 侧 provider 硬编码分支
- [ARCH-003] 跨运行时一致：同输入、同 manifest、同语义输出
- [TEST-001] compliance-first：合规测试是发布前门禁，不是补充项
- [DOC-001] 内部文档中文优先，术语统一

---

## 3. 全链路方案（Target Architecture）

## 3.1 Protocol 层（ai-protocol）

- 在 v2 能力模型中扩展生成式多模态能力描述：
  - 输入侧：文本/图像/音频/视频引用
  - 输出侧：文本/图像/音频/视频/结构化输出
  - 交互模式：sync / streaming / async-polling
- 保留 v1 兼容映射（降级能力与字段转换）
- 增补错误分类、重试与终止语义映射

## 3.2 Mock 层（ai-protocol-mock）

- 增加 P0 provider 的多模态模拟响应模板
- 覆盖 sync/stream/async 三模式
- 支持失败注入（429/5xx/timeout/invalid_content_type）

## 3.3 Runtime 层（三运行时）

- 按统一 capability contract 适配：
  - 请求映射、流式事件、错误归一、重试/回退语义
- 统一验证矩阵：
  - Provider x Modalities x Transport x Failure

## 3.4 Control Plane 层（spiderswitch）

- spiderswitch 仅做 runtime 路由执行与状态回传
- 策略保持上移，不在 spiderswitch 内下沉业务策略
- 输出可路由信号：模型能力 + 运行时能力 + 健康状态

---

## 4. P0/P1/P2 分层范围

## P0（4-6 周主线）

- Provider：
  - Global：OpenAI / Anthropic / Gemini
  - China：DeepSeek / Qwen / Doubao
- 能力：
  - 文本 + 图像 + 音频（STT/TTS）优先
  - 视频先做声明与 mock 验证框架（可实验）

## P1

- 扩展其他高价值 provider
- 完整视频生成/编辑链路语义
- 三运行时性能与稳定性调优

## P2

- Go/WASM 运行时预研与 adapter 契约落地
- 自动化漂移检测与定期对账机制

---

## 5. 风险矩阵与必要调整

| 风险 | 级别 | 调整措施 |
|------|------|----------|
| 文档事实与推测混用导致实现偏差 | 高 | 强制证据分级与 UNVERIFIED 标注 |
| runtime 各自实现导致语义漂移 | 高 | compliance-first + 跨运行时契约测试 |
| 新能力上线不可回滚 | 高 | feature flag + rollback trigger + rollback drill |
| provider 变化过快导致计划失效 | 中 | 增加“最后验证日期+来源”机制 |
| 多仓库协同节奏不一致 | 中 | 主任务+下游任务依赖编排 |

---

## 6. 验收指标（Execution KPIs）

- 协议覆盖：
  - P0 provider 的 v2 能力字段完成率 >= 95%
- 合规覆盖：
  - P0 场景 compliance 通过率 >= 95%
- 一致性：
  - 三运行时跨语义差异关键项为 0（P0 范围）
- 稳定性：
  - mock + 运行时回归用例通过率 >= 98%
- 可回滚：
  - 每个新增能力均有开关与回滚步骤

---

## 7. 审计结论

建议立即按“v2 主线 + P0 分层 + compliance-first”推进；  
先完成协议与验证框架，再做运行时大规模适配，最后由 spiderswitch 进行能力路由执行闭环。  
本结论已转化为 PT 任务卡并可直接执行。

