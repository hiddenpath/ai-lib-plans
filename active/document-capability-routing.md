# 文档能力路由 — 跨项目演进协调

> **状态**: 已立项（2026-06-28）  
> **性质**: 已知阶段性技术债的**正式出路**；与 ARCH-001（协议驱动）、E/P 分离、Contact 能力路由愿景对齐  
> **触发背景**: Eos Phase 2 `EOS-P2-006-R1` 以服务端 `pdf_extract` + 文本注入交付上传能力——为快速上线之权宜，**非**目标架构

---

## 1. 问题陈述

| 现状（权宜） | 目标（ai-lib 愿景） |
|--------------|---------------------|
| 应用侧 `pdf_extract` 抽文本 | 应用只表达 `Document` 附件 + 能力需求 |
| 任意文本模型均可「聊 PDF」 | 路由到 `document_understanding: true` 的模型 |
| 扫描件/版式/表格易丢失 | 厂商侧原生 document pipeline |
| 能力逻辑散落在 eos-server | manifest + Contact 路由 + Core driver 编码 |

**原则**：基于 ai-lib 的应用**不应**在语义层自行解析 PDF；应把用户文档交给**具备解析能力**的模型，由协议栈完成编码与分发。

---

## 2. 分阶段演进

```text
Stage 0  权宜交付（进行中）     EOS-P2-006-R1   pdf_extract + extracted_text 注入
Stage 1  协议与类型基建         ALR-DOC-001 ✅   ContentBlock::Document + 能力校验
Stage 2  产品迁移               EOS-P2-007      upload 返回 document_ref；路由/降级 UX
Stage 3  智能路由（可选增强）   EOS-REQ-P2-003  /v1/route/decide 按 document 需求选模
```

### Stage 0 — 权宜（不推翻）

- **任务**: `EOS-P2-006-R1`（`in_progress`，eos #22）
- **交付**: `/api/upload` 对 PDF 做文本抽取；UI 拼入 user message
- **标注**: 明确为**过渡实现**；Stage 2 完成后移除 `pdf_extract` 主路径
- **例外**: `text/plain`、`text/markdown` 仍为纯文本 block，不属于本债务

### Stage 1 — ai-lib Core 基建（上游阻塞）

- **任务**: `ALR-DOC-001`
- **范围**（`ailib-official/ai-lib-rust`）:
  - `ContentBlock::Document`（mime、ref/base64、filename）
  - `MultimodalCapabilities` 暴露 `document_understanding`
  - `detect_modalities` / `validate_content_modalities` 识别 document 需求
  - 各 provider driver 按 manifest 编码（Gemini inline_data、Claude document block 等）
- **协议**: 复用既有 `multimodal.input.vision.document_understanding`（**无需**新 provider manifest）；若需标准 schema 文档化，可另开 `PT-079`（非 Stage 1 阻塞）
- **跨 runtime**: Stage 1 仅 Rust；Python/TS parity 另任务（模式同 `ALR-TTC-002`）

### Stage 2 — Eos 产品迁移

- **任务**: `EOS-P2-007`
- **依赖**: `ALR-DOC-001` ✅；`EOS-P2-005-R2` ✅（`/v1` 壳已存在）
- **行为变更**:
  1. `POST /api/upload` 对 PDF **不再**默认 `pdf_extract`；返回 `document_ref`（+ 可选 staging URL）
  2. 发送路径构造 `ContentBlock::Document` + 用户文本
  3. 当前模型不支持 `document_understanding` → **显式**提示换模型或（若产品允许）用户确认降级——**禁止**静默抽文本冒充「模型读懂 PDF」
  4. 合规：`ComplianceFilter` 与 `EOS-ARCH-001` 区域模型表仍适用
- **与 EOS-P2-006 关系**: R1 完成后保留至 Stage 2 切换；Stage 2 验收后删除 `extract_pdf_text` 主路径

### Stage 3 — 智能路由增强（软依赖）

- **需求槽**: `EOS-REQ-P2-003`（已有，`deferred`）
- **增强**: `POST /v1/route/decide` 输入含 document 附件时，优先推荐 `document_understanding` 模型
- **参考**: `eos/docs/EOS-P2-005-R4-SMART-ROUTING-PLACEHOLDER.md`
- **SLA**: NOT PRODUCTION SLA（与 Prism gateway 一致）

---

## 3. 任务矩阵

| ID | 项目 | 状态 | 依赖 | 说明 |
|----|------|------|------|------|
| EOS-P2-006-R1 | eos | `in_progress` | — | 权宜 pdf_extract |
| ALR-DOC-001 | ai-lib-rust | `completed` | — | Document block + driver 编码 |
| EOS-P2-007 | eos | `planned` | ALR-DOC-001, EOS-P2-005-R2 | 迁移至能力路由 |
| EOS-REQ-P2-003 | eos↔prism | `deferred` | PT-073, Prism P2 | decide 按 document 选模 |

---

## 4. 架构约束（不得违反）

1. **ARCH-001**: 不在应用层硬编码 provider document API 形状；由 manifest + driver 完成
2. **BIZ-002**: 路由库（`prism-core` / Contact）A-band；Eos 降级策略与文案 C-band
3. **EOS-P2-005 ADR**: 前端不直调 Prism；document 路由经 eos-server P 层
4. **NEAR_TERM Prism P1**: 不将 document 迁移绑为 Prism P1 交付物；Stage 2 可走 eos `/v1` 壳 + 直连 provider document API
5. **DOC-002**: 本文档为内部规划，不写入公开产品 README

---

## 5. 验收口径（Stage 2 完成时）

- [ ] 上传 PDF 后请求体含 document block（非 extracted_text 注入）
- [ ] 选择纯文本模型 + PDF 附件 → 明确错误/换模提示（无静默 extract）
- [ ] 选择 Gemini/Claude 等 document 模型 → 厂商侧收到原生 document 载荷
- [ ] 扫描件 PDF 在 document 模型路径下可处理（或厂商返回可理解错误）
- [ ] `EOS-P2-006-R1` 的 `pdf_extract` 代码路径已移除或仅 feature-gated 应急

---

## 6. 相关文档

- `active/projects/eos/docs/EOS-DOC-001-document-capability-routing.md` — Eos 侧 ADR 摘要
- `active/projects/eos/PHASE2_PLAN.md` — Wave 4/5 排期
- `active/projects/eos/tasks/EOS-P2-006-feature-enhancements.yaml`
- `active/projects/eos/tasks/EOS-P2-007-document-capability-routing.yaml`
- `active/projects/ai-lib-rust/tasks/ALR-DOC-001-document-content-block.yaml`
- `ai-protocol/schemas/v2/multimodal.json` — `document_understanding`
