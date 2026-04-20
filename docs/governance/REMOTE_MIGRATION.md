# 远端迁移指令：hiddenpath → ailib-official（GOV-001 v2）

> **Effective**: 2026-04-06
> **Status**: 强制执行（mandatory）
> **Audience**: 所有编程代理、人类开发者、CI 系统

---

## 背景

自 2026-04-06 起，**ailib-official** 是所有公开代码仓库的**唯一**开发与发布组织。`hiddenpath` 上的公开仓库已**归档（archived）**，不再接受任何 push、PR 或 issue。

此决策记录于：
- `ai-lib-constitution/rules/governance/GOV-001-canonical-remote-monorepo-sync.yaml` (v2.0)
- `ai-lib-plans/MEMORY.md`（"CRITICAL — Canonical remote migration" 段落）

---

## 代理/开发者必须执行的操作

### 步骤 1：检查本地 origin

对以下每个仓库，运行：

```bash
git remote get-url origin
```

### 步骤 2：重指向（如果仍指向 hiddenpath）

```bash
git remote set-url origin https://github.com/ailib-official/<REPO_NAME>.git
```

适用仓库：

| 仓库名 | 正确 origin |
|--------|-------------|
| `ai-protocol` | `https://github.com/ailib-official/ai-protocol.git` |
| `ai-lib-rust` | `https://github.com/ailib-official/ai-lib-rust.git` |
| `ai-lib-python` | `https://github.com/ailib-official/ai-lib-python.git` |
| `ai-lib-ts` | `https://github.com/ailib-official/ai-lib-ts.git` |
| `ai-lib-go` | `https://github.com/ailib-official/ai-lib-go.git` |
| `ai-protocol-mock` | `https://github.com/ailib-official/ai-protocol-mock.git` |

### 步骤 3：验证

```bash
git fetch origin
git status
# 确认 branch 跟踪 ailib-official 的 main
```

### 不要重指向的仓库

| 仓库名 | 保持指向 | 原因 |
|--------|----------|------|
| `ai-lib-constitution` | `hiddenpath` | 私有治理仓，永不公开 |
| `ai-lib-plans` | `hiddenpath` | 私有规划仓，永不公开 |
| `papers` | `hiddenpath` | 私有论文仓；**必须**保留在 `hiddenpath`，不迁移至 `ailib-official` |

---

## CI / Workflow 规则

- 所有 `actions/checkout` 的 `repository:` 字段必须使用 `ailib-official/*`。
- 不再有 `hiddenpath/*` 的 workflow 引用例外。
- TEST-002 v2.0 不再为 `.github/workflows/**` 路径豁免 hiddenpath URL。

---

## npm 包名变更

- **新名称**：`@ailib-official/ai-lib-ts`（v0.6.0+）
- **旧名称**：`@hiddenpath/ai-lib-ts`（已废弃）
- 代码中的 import 路径从 `'@hiddenpath/ai-lib-ts'` 改为 `'@ailib-official/ai-lib-ts'`。

---

## 合法的 hiddenpath 残留

以下位置允许保留 `hiddenpath` 字样（不视为违规）：

| 位置 | 原因 |
|------|------|
| `ai-lib-ts/src/protocol/loader.ts` | `node_modules/@hiddenpath/ai-protocol` 向后兼容 fallback |
| `ai-lib-ts` CHANGELOG / README | 迁移说明中提及旧包名 |
| `ai-lib-plans` 历史任务 YAML | 历史记录（任务已关闭） |
| 本地 `papers` 克隆的 `origin` | 私有仓，合法为 `https://github.com/hiddenpath/papers.git` |
| `ai-protocol` 历史规划文档 | 日期快照，不做追溯修改 |
| `ai-lib-go` `go.mod` | Go 模块路径已为 `ailib-official`（无残留），但若未来出现 replace 指令可豁免 |

---

## 快速自检脚本

```bash
# 在工作区根目录运行，检查所有公开仓 origin 是否正确
for repo in ai-protocol ai-lib-rust ai-lib-python ai-lib-ts ai-lib-go ai-protocol-mock; do
  dir="<your-workspace>/${repo}"
  if [ -d "$dir/.git" ]; then
    url=$(git -C "$dir" remote get-url origin 2>/dev/null)
    if echo "$url" | grep -q "hiddenpath"; then
      echo "NEEDS FIX: $repo → $url"
    else
      echo "OK: $repo → $url"
    fi
  fi
done
```

---

## 相关文档

- GOV-001 v2.0: `ai-lib-constitution/rules/governance/GOV-001-canonical-remote-monorepo-sync.yaml`
- TEST-002 v2.0: `ai-lib-constitution/rules/testing/TEST-002-public-url-reference-hygiene.yaml`
- AGENTS.md: `ai-lib-constitution/AGENTS.md`（"Canonical remote" 检查项）
- Runbook: `ai-lib-plans/docs/governance/official-mirror-promotion.md`（历史模型说明 + 归档指引）
