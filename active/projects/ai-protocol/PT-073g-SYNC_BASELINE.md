# PT-073g — 多端同步基线

> **用途**: 质量审查可在 **本机 / LAN 其他节点 / CI 代理** 执行；开工前必须对齐本表 commit 与远端。  
> **更新**: 基线变更时 commit `ai-lib-plans` 并双推 `lan` + `origin`。  
> **任务**: [PT-073g](./tasks/PT-073g-cross-repo-quality-audit.yaml)

**基线日期**: 2026-06-30（多端同步 kickoff）

## 1. 仓库与远端策略

| 仓库 | 路径（Windows） | 主远端 | 备份远端 |
|------|-----------------|--------|----------|
| ai-lib-plans | `D:/ai-lib-plans` | `lan` | `origin` |
| ai-lib-constitution | `D:/ai-lib-constitution` | `lan` | `origin` |
| eos | `D:/rustapp/eos` | `lan` | `origin` |
| ai-protocol | `D:/ai-protocol` | `origin` (ailib-official) | — |
| ai-lib-rust/python/ts/go | `D:/rustapp/ai-lib-*` | `origin` | — |
| velaclaw / ailib.info / ai-lib-benchmark | `D:/rustapp/*` | `origin` | — |

公开运行时仓以 `ailib-official/*` `main` 为唯一真源（GOV-001）。

## 2. 基线 commit

| 仓库 | SHA | 说明 |
|------|-----|------|
| ai-lib-plans | `91e0032` | 本文件所在 tip（提交后更新此行） |
| ai-lib-constitution | `081bc81` | GOV/ARCH |
| eos | `1427438` | EOS-CX-001 R1 |
| ai-protocol | `65857ef` | PT-073f #17 |
| ai-lib-rust | `2f331b4` | 合规矩阵 |
| ai-lib-python | `c3f4d53` | PT-073f #6 |
| ai-lib-ts | `aa3f5fa` | PT-073f #7 |
| ai-lib-go | `2cf42c6` | PT-073f #3 |
| velaclaw | `d6e8f6a` | deps #81 |
| ailib.info | `ab86b8f` | 站点 |
| ai-lib-benchmark | `e65830a` | 可选 |

## 3. 同步

Windows: `powershell -File D:\ai-lib-plans\tools\sync_pt073g_repos.ps1`  
Linux: `bash /home/alex/ai-lib-plans/tools/sync_pt073g_repos.sh`

私有仓互推 `lan`/`origin`；公开仓 `reset --hard origin/main`。

## 4. checklist

- sync 脚本无 ERROR
- HEAD 与 §2 一致
- 报告目录 `reports/quality-audit/2026-06/`
- 双推 `lan` + `origin`