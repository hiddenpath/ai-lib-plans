# PT-050 Fullchain Rollback Integration Baseline

## 目标

将 fail-fast rollback drill 接入 fullchain 门禁作为可选阶段，在不改变默认 fullchain 行为的前提下，实现一次执行即可覆盖常规门禁与回滚演练证据。

## 代码改动

- `d:/ai-protocol/scripts/gate-fullchain.js`
  - 新增 `--with-rollback-drill` 开关
  - 支持 `FULLCHAIN_WITH_ROLLBACK_DRILL=1`
  - 开启后追加 `compliance-rollback-drill` 阶段
  - 报告新增 `options.with_rollback_drill`
- `d:/ai-protocol/package.json`
  - 新增脚本 `gate:fullchain:with-rollback`
- `d:/ai-protocol/README.md`
  - 补充命令入口与脚本说明

## 执行与结果

- `npm run gate:fullchain -- --report-only` -> pass
  - `d:/ai-protocol/reports/fullchain-gates/fullchain-gate-2026-03-17T16-20-33-822Z.json`
- `npm run gate:fullchain:with-rollback -- --report-only` -> pass
  - `d:/ai-protocol/reports/fullchain-gates/fullchain-gate-2026-03-17T16-21-42-226Z.json`
- `npm run gate:fullchain:with-rollback` -> pass
  - `d:/ai-protocol/reports/fullchain-gates/fullchain-gate-2026-03-17T16-26-13-987Z.json`

## 结论

PT-050 目标达成：fullchain 已支持“默认稳定 + 可选演练”的一体化治理执行路径，可在一次流水中同时沉淀正向门禁与负向演练证据。
