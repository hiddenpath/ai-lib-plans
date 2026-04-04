# P1 Provider Wave-2 生成式大模型选型与排期

> 状态：评分冻结（PT-060）
> 日期：2026-03-30
> 方法论：沿用 PT-019 (P1 Wave Plan) 五维评分法

## 1. 评分维度（1-5 分）

| 维度 | 权重 | 说明 |
|------|------|------|
| 生成式能力深度 | 25% | reasoning, structured output, long context, function calling 支持程度 |
| 需求匹配度 | 25% | 社区/生态使用量、已有请求 |
| API 契约成熟度 | 20% | 端点稳定性、文档完备度、错误码规范化 |
| 多模态生成支持 | 15% | text+image, text+code, text+video 生成能力 |
| 运维风险 | 15% | API 变更频率、breaking change 历史、SLA 可靠性 |

## 2. 候选评估（Wave-2）

### 全球

| Provider | 能力深度 | 需求匹配 | 契约成熟 | 多模态 | 运维风险 | 加权总分 | 建议 |
|----------|---------|---------|---------|--------|---------|---------|------|
| **Mistral** | 5 | 4 | 4 | 3 | 4 | **4.10** | **Wave-2A 首批** |
| **Grok (xAI)** | 4 | 4 | 3 | 3 | 3 | **3.50** | **Wave-2A 首批** |
| Meta Llama (hosted) | 4 | 5 | 3 | 2 | 3 | 3.55 | Wave-2B |
| Perplexity | 3 | 3 | 3 | 2 | 4 | 3.00 | Wave-2B 观察 |
| Reka | 3 | 2 | 2 | 3 | 3 | 2.55 | 暂缓 |

### 中国区

| Provider | 能力深度 | 需求匹配 | 契约成熟 | 多模态 | 运维风险 | 加权总分 | 建议 |
|----------|---------|---------|---------|--------|---------|---------|------|
| **MiniMax** | 4 | 4 | 4 | 4 | 4 | **4.00** | **Wave-2A 首批** |
| **Baichuan** | 4 | 3 | 3 | 3 | 4 | **3.40** | **Wave-2A** |
| Yi (01.AI) | 4 | 3 | 3 | 2 | 3 | 3.10 | Wave-2B |
| Stepfun | 3 | 2 | 3 | 4 | 3 | 2.95 | Wave-2B 观察 |
| SenseNova | 3 | 2 | 2 | 3 | 3 | 2.55 | 暂缓 |

### 专用生成

| Provider | 能力深度 | 需求匹配 | 契约成熟 | 多模态 | 运维风险 | 加权总分 | 建议 |
|----------|---------|---------|---------|--------|---------|---------|------|
| Stability AI | 3 | 3 | 3 | 5 | 3 | 3.30 | Wave-2B（图像生成） |
| ElevenLabs | 2 | 3 | 4 | 2 | 4 | 2.95 | Wave-2B（TTS 专用） |
| Runway | 2 | 2 | 2 | 5 | 2 | 2.45 | 暂缓（视频生成不稳定） |

## 3. Wave-2A 执行排期（首批 4 个）

| 顺序 | Provider | 理由 | 预计周期 |
|------|----------|------|---------|
| 1 | **Mistral** | 评分最高，API OpenAI-compatible，onboarding 成本低 | 1 周 |
| 2 | **MiniMax** | 中国区最成熟，多模态支持好 | 1 周 |
| 3 | **Grok (xAI)** | 高关注度，API 稳定中 | 1 周 |
| 4 | **Baichuan** | 中国区补充，契约相对清晰 | 1 周 |

## 4. 每 Provider Onboarding 检查表

对每个 Wave-2A provider，以下步骤必须顺序完成：

- [ ] `ai-protocol`: 创建 `v2/providers/{provider}.yaml` manifest
  - 填充 capabilities (required/optional/feature_flags)
  - 填充 error_classification 映射
  - 填充 streaming decoder/event_map
  - 填充 metadata.models（context_window, pricing）
- [ ] `ai-protocol-mock`: 添加 provider 到 `/providers` 列表
  - 确保 mock 能响应 provider 特定的 chat/streaming 路径
- [ ] `ai-lib-rust`: generative manifest consumption 测试扩展
- [ ] `ai-lib-python`: generative manifest consumption 测试扩展
- [ ] `ai-lib-ts`: protocol-v2 compliance 消费扩展
- [ ] `ai-lib-go`: loader + streaming 测试扩展
- [ ] `spiderswitch`: capability signal 消费验证
- [ ] `compliance gate`: drift:check + gate:compliance-matrix 证据刷新
- [ ] 文档: ailib.info provider matrix 更新

## 5. 风险登记与回滚

| 风险 | 缓解措施 | 回滚动作 |
|------|---------|---------|
| Provider API 在集成期间变更 | 锁定 API version 在 manifest | 回退 manifest 文件 |
| 跨运行时语义偏差 | 共享 compliance fixture 验证 | 逐仓回退 |
| 多 provider 合并导致混合回归 | 每 provider 单独 PR | revert 单 PR |

## 6. Wave-2B 规划（后续）

Wave-2A 闭环后评估 Wave-2B（Meta Llama / Yi / Stepfun / Stability AI / ElevenLabs），
按同样流程评分冻结后启动。
