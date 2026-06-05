# LAN 基础设施（GOV-005）— 任务索引

> **Rule**: `ai-lib-constitution/rules/governance/GOV-005-lan-infra.yaml`  
> **详表**: [LAN_INFRA.md](./LAN_INFRA.md)  
> **Git 协作**: [docs/governance/LAN_GIT.md](../../docs/governance/LAN_GIT.md)

## 执行安排（2026-06-05 起）

| 阶段 | 目标 | 任务 |
|------|------|------|
| **P0 治理对齐** | 规则/文档/remote 一致 | INFRA-001 ✅ |
| **P1 备份可验证** | 双重 gitmirror 可恢复 | INFRA-002 |
| **P1 仓库矩阵** | LAN 上 bare 仓与文档一致 | INFRA-003 |
| **P2 轻量 CI** | piubt/git-server fmt+clippy | INFRA-004 |
| **持续** | eos 合并后 lan 同步 | 各 EOS 任务 + GOV-003 Phase 4b |

## 任务列表

| ID | 文件 | 状态 | 说明 |
|----|------|------|------|
| INFRA-001 | [tasks/INFRA-001-gov005-governance-align.yaml](./tasks/INFRA-001-gov005-governance-align.yaml) | `completed` | GOV-005 v1.1 YAML、LAN_INFRA、任务索引 |
| INFRA-002 | [tasks/INFRA-002-backup-verify.yaml](./tasks/INFRA-002-backup-verify.yaml) | `open` | 验证 post-receive + 日备 + 恢复演练 |
| INFRA-003 | [tasks/INFRA-003-repo-matrix-sync.yaml](./tasks/INFRA-003-repo-matrix-sync.yaml) | `open` | 核对 7 bare 仓状态与 push 缺口 |
| INFRA-004 | [tasks/INFRA-004-light-ci-runner.yaml](./tasks/INFRA-004-light-ci-runner.yaml) | `open` | piubt 轻量 CI（fmt/clippy/unit） |

## 协作约定

- 文档/治理变更：只推 **`git push lan main`**（GOV-004/005）
- eos 重型 CI：GitHub `origin` → 合并后 **24h 内** `git push lan main`
- Spider / Cursor：以内网 `git-server.local` 为同步源
