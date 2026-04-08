# ailib-official 统一组织（Runbook）

> **Status**: GOV-001 v2.0 — ailib-official is the single canonical org for all public repos.

**Previous model** (GOV-001 v1.x): hiddenpath = development, ailib-official = mirror, promote via bot PR.
**Current model** (GOV-001 v2.0): ailib-official = development + release, hiddenpath public repos = archived/read-only.

---

## 1. 职责划分

| 组织 | 用途 |
|------|------|
| `ailib-official` | 所有公开仓库的日常开发、PR、Issue、CI、发布 |
| `hiddenpath` | 仅保留 `ai-lib-constitution`（私有）和 `ai-lib-plans`（私有）；公开代码仓已归档 |

---

## 2. 本地配置

```bash
# 所有公开仓 origin 指向 ailib-official
git remote get-url origin
# → https://github.com/ailib-official/<repo>.git
```

---

## 3. hiddenpath 公开仓处置

对 hiddenpath 上的以下仓库执行 **Archive**（GitHub Settings → Archive）：

- `hiddenpath/ai-protocol`
- `hiddenpath/ai-lib-rust`
- `hiddenpath/ai-lib-python`
- `hiddenpath/ai-lib-ts`
- `hiddenpath/ai-lib-go`
- `hiddenpath/ai-protocol-mock`

Archive 后仓库变为只读，保留历史但不接受新 push/PR/issue。

---

## 4. npm 包名

- 新名称：`@ailib-official/ai-lib-ts`（v0.6.0+）
- 旧名称 `@hiddenpath/ai-lib-ts`：发布后执行 `npm deprecate` 并说明迁移包名。

---

## 5. 已废弃

- `promote-to-official.yml` workflow — 已删除，不再需要。
- `AILIB_OFFICIAL_PROMOTE_TOKEN` secret — 可从 hiddenpath 各仓清除。
- `compare_hiddenpath_official_main.sh` — 不再需要（两端不再同步维护）。
