# ai-protocol 生成式全链路升级发布收尾（2026-03-07）

## 1. 发布目标与范围

本次发布目标是完成“ai-protocol 生成式大模型支持能力全面升级”后的版本冻结与对外发布，范围覆盖：

- `ai-protocol`
- `ai-lib-rust`
- `ai-lib-python`
- `ai-lib-ts`
- `ailib.info` 文档对齐

## 2. 版本矩阵（已落地）

- `ai-protocol`: `0.7.8 -> 0.8.0`
- `ai-lib-rust`: `0.8.6 -> 0.9.0`
- `ai-lib-python`: `0.7.5 -> 0.8.0`
- `ai-lib-ts`: `0.4.1 -> 0.5.0`

## 3. 发布执行证据

### 3.1 代码与版本提交

- `ai-protocol`: `2b78702` (`release(protocol): bump to v0.8.0`)
- `ai-lib-rust`: `a83dacd` (`release(rust): bump to v0.9.0`)
- `ai-lib-python`: `6ddd0c5` (`release(python): bump to v0.8.0`)
- `ai-lib-ts`: `023264d` (`release(ts): bump to v0.5.0`)
- `ailib.info`: `a3fe746` (`docs(site): align ecosystem versions to 2026-03 release matrix`)

### 3.2 Tag / Release

- `ai-protocol`: tag `v0.8.0`，GitHub Release 已创建
- `ai-lib-rust`: tag `v0.9.0`，GitHub Release 已创建
- `ai-lib-python`: tag `v0.8.0`，GitHub Release 已创建
- `ai-lib-ts`: tag `v0.5.0`，GitHub Release 已创建

### 3.3 核心验证

- `ai-protocol`: `npm run validate` 通过
- `ai-lib-rust`: `cargo test --test generative_manifest_consumption --features multimodal` 通过
- `ai-lib-python`: `python -m pytest tests/integration/test_generative_manifest_consumption.py` 通过
- `ai-lib-ts`: `npm run test -- tests/protocol-v2.test.ts` 通过
- `ailib.info`: Prettier 检查通过（生态页与 Python quickstart 中英文）

## 4. 对外文档同步

已对齐 `ailib.info`：

- `src/content/docs/ecosystem.md`
- `src/content/docs/python/quickstart.md`
- `src/content/docs/zh-cn/python/quickstart.md`

对齐内容包括：

- 生态版本矩阵升级到本次发布版本
- Python 安装基线升级到 `v0.8.0+`

## 5. 本轮残留与边界说明

本轮发布未纳入与“生成式全链路升级”无关的本地历史改动（保持隔离）：

- `ai-protocol`: 本地 `RELEASE_NOTES_v0.7.5.md`、`reports/`（未跟踪）
- `ai-lib-rust`: `src/types/mod.rs` 与若干本地日志/临时文件（历史改动）
- `ai-lib-python`: `guardrails/*` 历史改动（未进入本轮版本提交）

## 6. 结论

本次发布已完成“先能力闭环再版本提升”的策略要求，形成“协议 + 三运行时 + 文档站点”的一致版本基线。下一阶段进入 P1/P2 Wave-2 执行。

