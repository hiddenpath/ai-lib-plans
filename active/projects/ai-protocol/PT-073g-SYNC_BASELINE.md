# PT-073g — 多端同步基线

> **用途**: 质量审查可在 **本机 / LAN 其他节点 / CI 代理** 执行；开工前必须对齐本表 commit 与远端。  
> **更新**: 基线变更时 commit `ai-lib-plans` 并双推 `lan` + `origin`。  
> **任务**: [PT-073g](./tasks/PT-073g-cross-repo-quality-audit.yaml)

**基线日期**: 2026-06-29（审查 kickoff）

---

## 1. 仓库与远端策略

| 仓库 | 路径（Windows） | 路径（Linux） | 主远端 | 备份远端 | 审查角色 |
|------|-----------------|---------------|--------|----------|----------|
| ai-lib-plans | `D:/ai-lib-plans` | `/home/alex/ai-lib-plans` | `lan` | `origin` (hiddenpath) | 任务/报告真源 |
| ai-lib-constitution | `D:/ai-lib-constitution` | `/home/alex/ai-lib-constitution` | `lan` | `origin` | 规则引用 |
| eos | `D:/rustapp/eos` | `/home/alex/eos` | `lan` | `origin` (hiddenpath) | Dim 5/6 抽样 |
| ai-protocol | `D:/ai-protocol` | `/home/alex/ai-protocol` | `origin` (ailib-official) | — | 规范 + 合规 |
| ai-lib-rust | `D:/rustapp/ai-lib-rust` | `/home/alex/ai-lib-rust` | `origin` | — | E 层参考 |
| ai-lib-python | `D:/rustapp/ai-lib-python` | `/home/alex/ai-lib-python` | `origin` | — | E 层 |
| ai-lib-ts | `D:/rustapp/ai-lib-ts` | `/home/alex/ai-lib-ts` | `origin` | — | E 层 |
| ai-lib-go | `D:/rustapp/ai-lib-go` | `/home/alex/ai-lib-go` | `origin` | — | E 层 |
| velaclaw | `D:/rustapp/velaclaw` | `/home/alex/velaclaw` | `origin` | — | text-tool 下游 |
| ailib.info | `D:/rustapp/ailib.info` | `/home/alex/ailib.info` | `origin` | — | 对外文档 |
| ai-lib-benchmark | `D:/rustapp/ai-lib-benchmark` | `/home/alex/ai-lib-benchmark` | `origin` | — | 可选 live 测试 |

公开运行时仓 **不适用** GOV-004 `lan`；以 `ailib-official/*` `main` 为唯一真源。

---

## 2. 基线 commit（kickoff）

| 仓库 | `main` SHA | 说明 |
|------|------------|------|
| ai-lib-plans | `08634fa` | PT-073g 计划/模板 + EOS-CX/TTC 任务 |
| ai-lib-constitution | `081bc81` | GOV/ARCH 规则 |
| eos | `1427438` | EOS-CX-001 R1 priority |
| ai-protocol | `65857ef` | PT-073f #17 merge |
| ai-lib-rust | `2f331b4` | PT-073 合规矩阵基线 |
| ai-lib-python | `c3f4d53` | PT-073f #6 |
| ai-lib-ts | `aa3f5fa` | PT-073f #7 |
| ai-lib-go | `2cf42c6` | PT-073f #3 |
| velaclaw | `d6e8f6a` | deps bump #81（VL-TTC 基线 `22d4195` 之上） |
| ailib.info | `ab86b8f` | 站点文档 |
| ai-lib-benchmark | `e65830a` | 基准工具（可选） |

验证：

```bash
git rev-parse --short HEAD   # 应等于上表
```

---

## 3. 同步命令

### Windows（PowerShell）

```powershell
D:\ai-lib-plans\tools\sync_pt073g_repos.ps1
# 演练：
D:\ai-lib-plans\tools\sync_pt073g_repos.ps1 -DryRun
```

### Linux / Git Bash

```bash
bash /home/alex/ai-lib-plans/tools/sync_pt073g_repos.sh
# 或
bash D:/ai-lib-plans/tools/sync_pt073g_repos.sh --dry-run
```

脚本行为：

1. `fetch --all --prune` 全部仓库  
2. **私有双远端**（plans / constitution / eos）：对齐 `lan/main` ↔ `origin/main`（互推落后方）  
3. **公开仓**：`reset --hard origin/main`  
4. 打印与基线表对照；偏差非 0 时 exit 1  

---

## 4. 执行端 checklist

- [ ] 已配置 `lan` SSH（`git-server.local`）与 GitHub 凭据
- [ ] 运行 `sync_pt073g_repos` 无 ERROR
- [ ] 各仓 `HEAD` 短 SHA 与 §2 一致（或已更新本文件）
- [ ] `ai-lib-plans` 在 `reports/quality-audit/2026-06/` 写报告
- [ ] 报告提交后 `git push lan main && git push origin main`

---

## 5. 基线变更流程

1. 完成一轮审查或合并关键 PR 后，更新 §2 表  
2. commit `ai-lib-plans`（引用 PR/merge commit）  
3. 双推 `lan` + `origin`  
4. 通知其他执行端拉取并重跑同步脚本
