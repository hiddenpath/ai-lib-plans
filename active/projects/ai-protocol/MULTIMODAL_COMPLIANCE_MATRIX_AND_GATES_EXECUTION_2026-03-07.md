# PT-012 执行闭环包：Multimodal Compliance Matrix & Gates（2026-03-07）

## 目标

建立并落地 compliance-first 多模态验证矩阵与跨运行时门禁，使后续能力扩展先过契约与语义一致性，再进功能发布。

## 验证矩阵（Provider x Modality x Transport x Failure）

### Provider 分层
- P0-Global: OpenAI / Anthropic / Gemini
- P0-CN: DeepSeek / Qwen / Doubao

### Modality
- text / image / audio(stt/tts) / video(contract-ready)

### Transport
- sync
- streaming
- async polling

### Failure
- 429 rate_limited
- 5xx overloaded/server_error
- timeout
- invalid_content_type

## 跨运行时语义门禁（Rust/Python/TS）

关键一致性断言：
1. 相同输入 + 相同 manifest => 语义等价输出（ARCH-003）
2. 事件顺序一致：start -> delta/chunk -> end/error
3. 错误分类一致：标准 error_class 不漂移
4. 重试/回退一致：同一错误同一 retryability 判定
5. 降级行为一致：不支持能力路径走显式降级/报错，不静默吞并

## 门禁分层

### Gate-0（快速回归）
- 覆盖 P0 provider 的核心 text/stream/error 场景
- 用于 PR 快速拦截语义漂移

### Gate-1（完整矩阵）
- 覆盖多模态 + 传输模式 + 失败注入全组合（按优先级抽样）
- 用于发布前强制门禁

## 质量阈值

- P0 关键场景通过率 >= 95%
- 关键语义漂移项（事件顺序、错误分类、重试判定）= 0
- 回归失败必须附带根因归类与修复时限

## 试点闭环证据（Pilot）

建议试点：
- provider: Gemini
- modality: image + audio + video(contract)
- transport: streaming + async polling
- failure: 429 + timeout

记录模板：
- case_id
- runtime_results (rust/python/ts)
- semantic_diff (none|detail)
- gate_result (pass|hold|fail)

## 风险与回滚

风险：
- 矩阵过大导致 CI 时长膨胀
- 运行时实现差异导致门禁波动

回滚：
- Gate-0 保持强制，Gate-1 可按发布窗口切换为分批执行
- 出现高噪声时进入 report-only 模式，先修复用例定义再恢复强制

## 监督机制（执行推进）

- 周监督节奏：每周 2 次 gate review（周二/周五）
- 责任划分：
  - 协议 owner：维护矩阵定义和 case 分层
  - 运行时 owner：修复语义差异
  - 发布 owner：裁决 GO/HOLD/NO-GO
- 升级规则：
  - 连续 2 次 gate fail -> 触发专项修复小组

## 产出清单

- 矩阵定义与门禁标准（本文件）
- 试点执行模板
- 监督推进节奏与升级规则
