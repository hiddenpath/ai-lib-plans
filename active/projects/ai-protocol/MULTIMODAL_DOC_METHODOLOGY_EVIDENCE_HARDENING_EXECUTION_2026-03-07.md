# PT-011 执行闭环包：Multimodal Doc Methodology & Evidence Hardening（2026-03-07）

## 目标

将多模态调研/集成文档从“叙述型”升级为“可验证型”，确保后续实施可复现、可审计、可回滚。

## 方法学框架（Methodology）

评估维度：
1. 事实性（是否有来源证据）
2. 可执行性（是否能映射到任务与测试）
3. 一致性（是否与 ARCH-001/ARCH-003 对齐）
4. 风险可控性（是否有回滚与门禁）

结论分级：
- A: 已证实（官方文档/实现验证/测试证据）
- B: 高可信推断（多源交叉，待最终验证）
- C: 假设（必须标记 UNVERIFIED）

## 证据分级规范（Evidence Levels）

- `E1_OFFICIAL`: 官方文档或规范
- `E2_IMPLEMENTED`: 已实现并有测试/运行证据
- `E3_EXPERIMENTAL`: 实验或 PoC 证据
- `E4_ASSUMPTION`: 仅设计假设（必须标记）

文档条目模板：
- claim
- evidence_level
- source
- last_verified_at
- implementation_impact

## Schema-Gap 分类表（Field-Level）

分类标签：
- `supported`
- `needs_schema_change`
- `experimental`

建议字段（示例）：
- multimodal.output.video: `supported`（契约已加）
- video job progress payload: `needs_schema_change`
- cross-provider video edit graph: `experimental`

## 编辑一致性清单（Editorial Consistency）

- 统一章节编号风格
- 术语统一：capability / transport / gate / rollback
- 去除模糊措辞（例如“可能”“应该”无上下文）
- 所有假设加 `UNVERIFIED` 标签
- 每个关键结论附最近验证日期

## 产出对实施的映射

- 输出直接映射到：
  - PT-012（矩阵与门禁）
  - PT-013（发布回滚与开关）
  - PT-019+（P1/P2 扩展执行）

## 风险与回滚

风险：
- 文档治理未落地到执行门禁，导致“写完不执行”
- 证据标注漂移，影响结论可信度

回滚：
- 若模板引入过高维护成本，保留核心字段最小集（claim/evidence/source/date）
- 先在关键章节强制执行，其他章节分批迁移

## 监督推进机制

- 与 `IMPLEMENTATION_SUPERVISION_BOARD_P1P2_2026-03-07.md` 联动
- 周监督检查新增指标：
  - `evidence_tag_coverage`
  - `unverified_item_clearance_rate`

## 执行结论

PT-011 的“方法学 + 证据分级 + schema-gap 清晰化 + 编辑一致性”要求已形成执行态闭环产物，可作为后续文档治理基线。
