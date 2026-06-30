# 质量审查报告 — ai-lib-go（Dim 3-4）

<!-- AUDIT_META: dimension=D3-D4 repo=ai-lib-go auditor=cursor date=2026-06-30 task=PT-073g status=final -->

> **任务**: [PT-073g](../../active/projects/ai-protocol/tasks/PT-073g-cross-repo-quality-audit.yaml)
> **维度**: Dim 3（代码质量）+ Dim 4（测试真实性）
> **仓库/范围**: `ailib-official/ai-lib-go`
> **审查人**: cursor · **日期**: 2026-06-30 · **基线**: `2cf42c6`

---

## 1. 执行摘要

| 指标 | 值 |
|------|-----|
| P0 | 0（QA-go-006 为 P0 候选，待运行时确认） |
| P1 | 3（QA-go-006 重试体复用、008 合规自证、009 CI 未 pin ref） |
| P2 | 2（QA-go-005/010） |
| 总体结论 | PASS_WITH_FIXES（QA-go-006 须运行时确认是否升 P0） |

**一段话结论**：无 goroutine、无 `panic` 热路径、无 `InsecureSkipVerify`，整体保守稳健。但有一处**重试复用同一已消费 `*http.Request`** 的真实缺陷：body 为一次性 `bytes.Reader`，首发后被消费，重试 POST 将发送空 body（重试测试仅校验命中数，掩盖此问题）。合规套件同样大量在测试内重实现逻辑（且本地 `classify` 与生产 502 映射分歧），CI 亦未 pin protocol ref。

---

## 2. 范围与方法

- 包含：`pkg/ailib`、`internal/*`、`tests/compliance/`、`.github/workflows/{ci,pt073-go,release}.yml`
- 方法：错误忽略/重试路径阅读 + 合规 runner 调用链核对 + CI 审查（静态；QA-go-006 建议 runtime 复验）

---

## 3. 发现项登记表

| ID | 严重度 | 状态 | 位置 | 问题 | 建议修复 |
|----|--------|------|------|------|----------|
| QA-go-006 | P1（P0 候选） | open | `pkg/ailib/client.go:405-417,442-478` | 重试在同一已消费 `*http.Request` 上反复 `c.http.Do(req)`；body 为一次性 `bytes.NewReader`，重试 POST 发空/非法 body | 每次尝试重建 request，或设置/使用 `req.GetBody`；重试测试断言重发 body |
| QA-go-008 | P1 | open | `tests/compliance/compliance_test.go:595-717,233-356` | 合规重实现 stream decode/event mapping/tool accum/error classify/param mapping/retry decision → 验证的是测试内代码；本地 `classify` 无 502 分支（→E9999），生产映射 502→E3002，存在分歧 | runner 调用生产代码（`internal/stream`/`pkg/streaming`、`parseHTTPError`、`buildChatPayload`、`resilience`） |
| QA-go-009 | P1 | open | `.github/workflows/{ci,pt073-go,release}.yml` | `ai-protocol` checkout 无 `ref:` → 不可复现、红/绿静默翻转 | pin `ref:` 到兼容窗口内 tag/sha |
| QA-go-004 | P1 | open | `internal/stream/sse.go`；`client.go:666-672`（见 D1-D2） | 流式 `ExecutionMetadata.Usage` 始终空，测试不断言 Usage（假绿） | 见 D1-D2 QA-go-004 |
| QA-go-005 | P2 | open | `pkg/ailib/client.go:546-580` | core(E) 内硬编码 provider error-token 映射（仅 fallback） | 全量由 manifest `error_classification` 驱动 |
| QA-go-010 | P2 | open | `tests/compliance/compliance_test.go:119-181`；`generative_test.go:33` | 用例类别 08 从不运行；gen-001 fixture 缺失静默 `t.Skipf` | 增 08 runner；静默 skip 改 CI 硬失败 |
| QA-go-007 | P2 | open | `pkg/ailib/chat_enrich.go:55,60` | `_ = applyUsage(...)` 未检查错误 | 检查/返回或 debug 记录 |

---

## 4. 维度专项检查

### Dim 3 — 代码质量

| 检查项 | 结果 | 备注 |
|--------|------|------|
| IO/网络路径忽略错误 | ⚠️ | 仅 `_ = applyUsage`（非 IO，QA-go-007） |
| 热路径 `panic()` | ✅ | 无（仅 README 示例） |
| 硬编码 provider-slug switch | ✅ | 解码器按 manifest *format* 名分派，非 slug（core 内有 error-token fallback，QA-go-005） |
| 重试安全 | ❌ | QA-go-006（复用消费过的 request） |
| TODO/FIXME / goroutine 泄漏 | ✅ | 0 / 无 goroutine |

### Dim 4 — 测试真实性

| 检查项 | 结果 | 备注 |
|--------|------|------|
| `go test ./...` 在 main 跑全量合规 | ✅ | core 合规无 skip-on-missing（dir 缺失 `t.Fatalf`） |
| 合规调用生产代码 | ❌ | QA-go-008（多数重实现；本地 classify 与生产分歧） |
| 类别覆盖 | ⚠️ | 跑 01-07+09；**08 不跑**（QA-go-010） |
| `t.Skip` 有理由 | ⚠️ | 1 处静默 skip（generative gen-001） |
| CI checkout 正确 ref | ❌ | QA-go-009（无 ref pin） |

---

## 5. 证据附录

```bash
sed -n '405,417p;451,456p' pkg/ailib/client.go   # newRequest 一次性 body + 重试复用 req
rg -n "repository: ailib-official/ai-protocol" -A3 .github/workflows/*.yml   # 无 ref:
```

## 6. 签核

| 角色 | 姓名 | 日期 | 结论 |
|------|------|------|------|
| 审查人 | cursor | 2026-06-30 | PASS_WITH_FIXES（QA-go-006 运行时确认后定级） |
| Maintainer | | | 待评审 |

## 变更记录
| 日期 | 变更 |
|------|------|
| 2026-06-30 | 初稿 |
