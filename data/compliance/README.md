# 生成式 AI 备案模型清单（EOS-ARCH-R5）

## 文件

| 路径 | 用途 |
|------|------|
| `registered_models.yaml` | 机器可读备案条目，供 eos-server P 层 `ComplianceFilter` 消费 |
| `../tools/sync_compliance_registry.py` | 结构校验（非爬虫） |

## 维护 SOP

1. 网信办公示有新批次时，人工摘录主流模型条目写入 `registered_models.yaml`。
2. 每条须含 `备案编号`、`备案日期`；推荐同时填写 `provider_id` + `model_id` 与 manifest 对齐。
3. 运行校验：`python tools/sync_compliance_registry.py`
4. 同步到 eos 部署：复制或挂载同文件，设置 `EOS_COMPLIANCE_REGISTRY`（见 eos `.env.example`）。

Phase 2（可选）：Playwright 抓取 CAC 页面自动化，当前不做。
