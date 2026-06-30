# 质量审查报告 — ai-lib-go

<!-- AUDIT_META: dimension=D1-D2 repo=ai-lib-go auditor=cursor date=2026-06-30 task=PT-073g status=final -->

> **任务**: [PT-073g](../../active/projects/ai-protocol/tasks/PT-073g-cross-repo-quality-audit.yaml)
> **维度**: Dim 1（公共 API 面）+ Dim 2（E/P 深度边界）
> **仓库/范围**: `ailib-official/ai-lib-go`（module `github.com/ailib-official/ai-lib-go`，Go 1.21）
> **审查人**: cursor（cloud agent）
> **日期**: 2026-06-30
> **基线 commit**: `2cf42c6`（`main` @ 2026-06-30，PT-073f #3）

---

## 1. 执行摘要

| 指标 | 值 |
|------|-----|
| 抽样路径数 | `pkg/ailib`、`pkg/contact`、`pkg/streaming` 导出 + `internal/*` import 图 |
| P0 发现 | 0（D1/D2 范围内；QA-go-004 流式 usage 归 Dim 2/4，按 P1 计） |
| P1 发现 | 1（QA-go-004 流式 ExecutionMetadata.Usage 始终为空） |
| P2 发现 | 2（QA-go-001 重复 public 解码器、QA-go-003 死 public 类型） |
| 总体结论 | PASS_WITH_FIXES |

**一段话结论**：E/P 依赖方向正确（`pkg/ailib`→`internal/*`；`pkg/contact`/`pkg/streaming`→`pkg/ailib`），无策略层/provider 反向泄漏。两处 D1 整洁度问题：`pkg/streaming` 是一份与 `internal/stream` **重复且 client 未使用** 的公共 SSE 实现；`ExecutionResult[T]` 导出却无任何 API 返回。Dim 2 实质缺陷：流式路径的 `ExecutionMetadata.Usage` 始终为空（声称的"从末帧提取 usage"修复不在 client 路径，详见 D3-D4）。

---

## 2. 审查范围与方法

- **包含**: `pkg/ailib`、`pkg/contact`、`pkg/streaming`、`internal/{protocol,stream,resilience}`
- **排除**: `tests/`（归 Dim 4）
- **对照文档**: `README.md`、`CHANGELOG.md`、`go.mod`
- **方法**: import 方向核对 + 公共符号 vs README + 流式元数据填充路径追踪

---

## 3. 发现项登记表（D1-D2）

| ID | 严重度 | 状态 | 位置 | 问题 | 建议修复 |
|----|--------|------|------|------|----------|
| QA-go-004 | P1 | open | `internal/stream/sse.go:13-18`；`pkg/ailib/client.go:666-672` | 流式 `fillExecutionMetadata` 从不设 `Usage`（`internal/stream.Event` 无 usage 字段）；非流式于 `client.go:153` 正常设值。可用的 usage 解析器仅存在于**未被使用**的 `pkg/streaming.parseUsage` | 为 `internal/stream` 增 usage 解析，`fillExecutionMetadata` 从末帧填 `meta.Usage`；测试断言 Usage |
| QA-go-001 | P2 | open | `pkg/streaming/sse.go:1`；`README.md:170-178` | 公共 `pkg/streaming` 与 `internal/stream` 重复、client 不用、文档未述 | 下沉 `internal/` 或接入 `ChatStream` 并文档化；删冗余解码器 |
| QA-go-003 | P2 | open | `pkg/ailib/execution_result.go:33-37` | `ExecutionResult[T]` 导出但无 API 返回（死公共面） | E 方法返回它，或移出公共面 |
| QA-go-002 | P2 | open | `pkg/ailib/chat_enrich.go:12` | `EnrichNonstreamChatResponse`（impl 细节，参数 `manifest any`）暴露在公共 API | unexport / 移 internal |

---

## 4. 维度专项检查

### Dim 1 — 公共 API

| 检查项 | 结果 | 备注 |
|--------|------|------|
| `pkg/ailib` 导出与 README 一致 | ✅ | `NewClientBuilder`/`WithBaseURL/APIKey`/`Build`/`Chat`/`ChatStream`/`Stream.*`/`Close` |
| 内部物错置 pkg/ | ⚠️ | `pkg/streaming` 冗余（QA-go-001）；`EnrichNonstreamChatResponse` 暴露（QA-go-002） |
| 死公共面 | ⚠️ | `ExecutionResult[T]`（QA-go-003） |
| go.mod 路径/版本 | ✅ | `github.com/ailib-official/ai-lib-go`；`retract v0.0.1` |

### Dim 2 — E/P 深度边界

| 检查项 | 结果 | 备注 |
|--------|------|------|
| core 不 import 策略层 | ✅ | `pkg/ailib`→`internal/*` only |
| 依赖方向 E←P | ✅ | `pkg/contact`/`pkg/streaming`→`pkg/ailib` |
| provider 业务逻辑入 core | ⚠️ | `classifyProviderErrorCode` 硬编码 provider error token 作 fallback（mild ARCH-001，详见 D3-D4 QA-go-005） |
| ExecutionMetadata 跨 API 返回 | ⚠️ | 非流式 OK；**流式 Usage 空**（QA-go-004） |

---

## 5. 证据附录

```bash
# 依赖方向
rg -n "ailib-official/ai-lib-go/(internal|pkg)" pkg/contact pkg/streaming   # 仅指向 pkg/ailib
# 流式 usage 未填
sed -n '660,673p' pkg/ailib/client.go    # fillExecutionMetadata 无 Usage 赋值
sed -n '13,18p' internal/stream/sse.go   # Event 无 usage 字段
```

抽样路径：`pkg/ailib/client.go:660-672`（流式元数据填充缺口）、`pkg/streaming/sse.go`（冗余公共解码器）、`pkg/ailib/execution_result.go`（死公共类型）。

---

## 6. 签核

| 角色 | 姓名 | 日期 | 结论 |
|------|------|------|------|
| 审查人 | cursor | 2026-06-30 | PASS_WITH_FIXES（方向正确；流式 usage 须修） |
| Maintainer | | | 待评审 |

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-06-30 | 初稿 |
