# VelaClaw Trial 冒烟测试清单（VL-TRIAL-001）

> **DOC-002**：本文档仅存在于 `ai-lib-plans`（内网 `lan`），不得放入 `ailib-official/velaclaw` 公开仓。  
> 任务真源：`tasks/VL-TRIAL-001-trial-readiness.yaml`

## 前置

1. 代码已合入：
   - `ailib-official/velaclaw` PR #50（`protocol_adapter` model 修复）
   - `ailib-official/ai-protocol` PR #7（DeepSeek V4 + `dist/v2/providers/nvidia.json`）

2. 构建（Linux / piubt）：

```bash
cd velaclaw
git pull origin main
cargo build --release -p velaclaw
```

3. 环境变量

```bash
export AI_PROTOCOL_DIR=/path/to/ai-protocol   # 含更新后的 dist/
export AI_PROXY_URL=http://192.168.2.13:8887    # ai-lib-rust 读 AI_PROXY_URL，非 http_proxy
export DEEPSEEK_API_KEY=...
export NVIDIA_API_KEY=...
export OPENAI_API_KEY=...   # 可选
```

非交互 shell（cron、daemon）勿只依赖 `~/.bashrc`；密钥应写入 `~/.profile` 或双方共用的 `~/.env`。

4. 配置

```bash
velaclaw onboard
# 参考 dev/config.byok.example.toml，复制到 ~/.velaclaw/config.toml
```

## 冒烟项（G/H/I）

```bash
velaclaw providers
velaclaw models list --protocol

velaclaw agent -m "hello"
velaclaw agent -m "hello" --provider nvidia/moonshotai/kimi-k2-instruct
velaclaw agent -m "hello" --stream   # 若 CLI 支持
```

## 代理 + DeepSeek 独立验证（curl）

```bash
curl -s -x http://192.168.2.13:8887 \
  https://api.deepseek.com/v1/chat/completions \
  -H "Authorization: Bearer $DEEPSEEK_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"deepseek-v4-pro","messages":[{"role":"user","content":"hi"}],"max_tokens":20}'
```

## 回填

完成后更新 `VL-TRIAL-001-trial-readiness.yaml` 的 `testing.evidence` 与 `completion_notes`。
