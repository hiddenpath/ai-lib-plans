# PT-073g — 六维审查速查清单

> 配合 [QUALITY_AUDIT_REPORT_TEMPLATE.md](./QUALITY_AUDIT_REPORT_TEMPLATE.md) 使用。  
> 每项标记: ✅ 通过 | ⚠️ P1 | 🔴 P0 | ➖ 不适用 | ⏳ 未查

---

## 仓库轮转表（建议顺序）

| 序 | 仓库 | D1 | D2 | D3 | D4 | D5 | D6 |
|----|------|----|----|----|----|----|-----|
| 1 | ai-protocol | | | | | | |
| 2 | ai-lib-rust | | | | | | |
| 3 | ai-lib-python | | | | | | |
| 4 | ai-lib-ts | | | | | | |
| 5 | ai-lib-go | | | | | | |
| 6 | eos | ➖ | ⚠️ | | | 🔴 | |
| 7 | velaclaw | | | | | | |
| 8 | ailib.info | ➖ | ➖ | ➖ | ➖ | ➖ | |

---

## Dim 1 — 公共 API

- [ ] `lib.rs` / `__init__.py` / `index.ts` / 根 `go.mod` 导出与文档一致
- [ ] `pub use` / re-export 未暴露内部模块路径
- [ ] Workspace 多 crate 版本号策略一致
- [ ] 已废弃 API 有 `deprecated` 标注或 CHANGELOG
- [ ] WASM 导出函数列表与 PT-061 文档一致

## Dim 2 — E/P 深度

- [ ] `check_ep_boundary.py --{rust,python,ts,go}-root` 绿（基线）
- [ ] Feature flags 未默认开启 P 依赖
- [ ] `ai-lib-contact` 不 import provider 驱动实现
- [ ] 测试 fixtures 未从 P 层 copy-paste 业务逻辑
- [ ] eos / velaclaw 依赖图：core ← contact ← app

## Dim 3 — 代码质量

- [ ] `rg 'unwrap\(|expect\(|panic!|unimplemented!' {hot_path}` 审查
- [ ] `rg 'TODO|FIXME|HACK'` 高密度区分类
- [ ] Python: 无裸 `except:`；TS: 无滥用 `any`
- [ ] Go: error 未 `_` 忽略在 IO/网络路径
- [ ] 无 duplicate provider slug 硬编码（ARCH-001）

## Dim 4 — 测试真实性

- [ ] 列出 `COMPLIANCE_SUBSET` / `e_only` 与 full 差异
- [ ] `#[ignore]` / `@pytest.mark.skip` 清单 + 理由
- [ ] compliance cases 数量 vs 各运行时 runner 注册数
- [ ] CI workflow 是否 checkout 正确 `ai-protocol` ref
- [ ] 最近一次 rollback drill / fullchain gate 时间戳

## Dim 5 — 安全

- [ ] `rg -i '(api[_-]?key|secret|password|token)\s*=\s*["\']'` 在源码（排除 test mock）
- [ ] GitHub Actions secrets 引用无 echo
- [ ] HTTP client: proxy 默认、证书校验
- [ ] eos: BIZ-004 密文同步路径无 plaintext 落盘
- [ ] `cargo audit` / `npm audit` / `pip-audit` 摘要（可选）

## Dim 6 — 文档迁移

- [ ] 各仓库 CHANGELOG `[Unreleased]` vs main 差异
- [ ] WAVE5 checklist 勾选与任务 YAML 一致
- [ ] `text-tool-call-standard.md` Phase 状态准确
- [ ] `MEMORY.md` 含 v1.0 defer + PT-073g 引用
- [ ] ailib.info 包名/安装命令可复现

---

## P0 快速判定（任一即阻塞 1.0）

1. Core 包可 import P 层类型或发起未授权外呼
2. 已知数据泄漏路径（日志/存储/同步）
3. 公共 API 与发布物不一致且无迁移说明
4. CI full matrix 假绿（subset 通过但 full 已知失败未文档化）
5. 合规 rollback drill 失败未修复
