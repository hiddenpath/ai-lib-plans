# PT-013 执行闭环包：Multimodal Rollout/Rollback/Flag Policy（2026-03-07）

## 目标

建立多模态能力发布与回滚可执行策略，确保“可灰度、可观测、可回退”。

## Feature Flag 策略

按能力域拆分（默认关闭）：
- `mm_text_image`
- `mm_audio_stt`
- `mm_audio_tts`
- `mm_video_generation`
- `mm_video_editing`

按 provider 细分：
- `provider_<name>_enabled`
- `provider_<name>_mm_video_enabled`

按环境分层：
- dev -> staging -> canary -> general

## 发布节奏（Rollout）

1. 预发布（staging）
- 启用能力 flag，执行 Gate-0 + Gate-1
- 检查语义一致性与错误分布

2. 金丝雀（canary）
- 小流量启用（建议 5%-10%）
- 重点监控延迟、错误率、回退率

3. 全量（general）
- 达到阈值后推进全量
- 保留一键回滚路径与责任人在线

## 回滚触发阈值（Trigger）

任一触发即回滚：
- 错误率超过基线 +30% 且持续 15 分钟
- p95 延迟超过阈值 +20% 且持续 15 分钟
- 关键语义漂移 > 0（事件顺序/错误分类/重试判定）
- 跨运行时差异造成用户侧行为不一致

## 回滚流程（Runbook）

1. 宣告回滚事件（owner + 时间戳）
2. 关闭对应能力/provider flags
3. 切换至上一个稳定配置快照
4. 执行关键回归（Gate-0 子集）
5. 发布回滚结果与后续修复计划

## 回滚演练模板（Drill）

演练频率：
- 每月一次
- 重大能力上线前必演练

演练记录字段：
- drill_id
- trigger_type
- rollback_time_to_stable
- affected_scope
- residual_risk
- followup_actions

## 风险与缓解

风险：
- 开关粒度不够导致“误伤”范围过大
- 阈值过敏引发抖动回滚

缓解：
- 按能力+provider 双维开关
- 引入“持续时间”窗口避免瞬时噪声

## 监督机制（推进实施）

- 发布监督看板（周级）：
  - flag 覆盖率
  - drill 完成率
  - rollback 准备度评分
- 责任机制：
  - policy owner：阈值与流程维护
  - runtime owner：回滚技术执行
  - release owner：发布决策与复盘

## 产出清单

- rollout 分层策略
- rollback trigger 与 runbook
- 演练模板与监督看板字段
