# EOS-DOC-001 — 文档能力路由演进 ADR

**状态**: Accepted（规划记录，2026-06-28）  
**决策者**: Eos + ai-lib 生态对齐  
**协调真源**: [`../../../document-capability-routing.md`](../../../document-capability-routing.md)

---

## 背景

`EOS-P2-006-R1` 在 eos-server 使用 `pdf_extract` 抽取 PDF 文本，前端将 `extracted_text` 拼入 user message。这使任意文本模型看似「支持 PDF」，但与 ai-lib **能力路由与分发**愿景冲突：

- 语义解析发生在应用层（C-band 产品壳），而非 Contact/Core 按 manifest 分发
- 扫描件、版式、表格信息丢失
- 用户无法感知真实模型能力边界

## 决策

1. **承认 R1 为阶段性技术债**，完成交付但不作为终态
2. **终态**：PDF 以 `Document` content block 提交，由具备 `document_understanding` 的模型在厂商侧解析
3. **迁移任务**：`EOS-P2-007`（依赖 `ALR-DOC-001`）
4. **降级**：仅允许**显式**用户确认或换模提示，禁止静默 `pdf_extract`

## 与现有规划的关系

| 文档/任务 | 关系 |
|-----------|------|
| `EOS-P2-006-R1` | Stage 0 权宜；不阻塞 R2/R3；Stage 2 后退役 extract 主路径 |
| `EOS-P2-005` | `/v1` 壳 ✅；document 编码走同一代理路径 |
| `EOS-P2-005-R4` | Stage 3 智能路由占位；`EOS-REQ-P2-003` |
| `EOS-CX-002` | 外部文档化/recall 正交；不替代 document 路由 |
| `PHASE2_PLAN` Wave 4/5 | Wave 4 完成权宜上传；Wave 5 启动能力路由迁移 |

## 数据流（目标）

```text
Browser → POST /api/upload (PDF)
       → { kind: document, document_ref, mime }
       → build Message [ Text + Document{ref} ]
       → eos-server: validate model.document_understanding
       → ai-lib driver: encode per manifest → Provider API
```

## 非目标（本 ADR）

- 不在 eos-server 实现 OCR/版面分析
- 不要求 Prism P1 为 Eos 增加 document 专用端点
- 不将 txt/md 改为 document block（保持 text）

## 开放项

- ~~`PT-079` 标准 schema 文档化~~ ✅ 已完成（Stage 3）
- ~~`EOS-REQ-P2-003` 智能路由~~ ✅ 已完成（Stage 4 #26+#27）
- Python/TS `ContentBlock::Document` parity（ALR-DOC-001 之后另任务；模式同 `ALR-TTC-002`）
