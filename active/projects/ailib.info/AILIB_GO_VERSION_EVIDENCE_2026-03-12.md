# ailib.info Go 版本号校准证据（2026-03-12）

## 结论

- 本次站点收口将 `ai-lib-go` 统一标注为 **v0.5.0**。  
- 主要依据：`ai-lib-go` 代码与文档链路显示“初始发布语义从 v0.5.0 开始”。  
- 同时记录到：仓库当前存在 `v0.0.1` tag，属于版本治理口径冲突，需后续在 `ai-lib-go` 发布链路内进一步校正。

## 证据清单

1. `ai-lib-go` 提交历史包含初始发布语义：
   - `5ac6356 feat: initial release of ai-lib-go v0.5.0`

2. `ai-lib-go` README 明确写有 V0.5.0 基线描述：
   - `V0.5.0 includes V1/V2 manifest parsing...`

3. `ai-lib-go` CHANGELOG 当前 `Unreleased` 区块持续沿用 GO-001 后续迭代描述，
   与“从 v0.5.0 起步后持续迭代”的产品叙事一致。

4. `git tag --sort=version:refname` 当前仅显示 `v0.0.1`：
   - 该结果与 1/2 项证据冲突，判定为发布记录口径不一致，而非站点文档应继续采用 `v0.0.1` 的充分证据。

## 本次执行动作

- `ailib.info` 中所有 `ai-lib-go v0.0.1` 展示已统一替换为 `v0.5.0`：
  - Go landing page（EN/ZH/JA/ES）徽标与安装命令
  - intro/ecosystem（EN/ZH/JA/ES）版本矩阵文本
- 站点构建验证通过：`npm run build`

## 后续建议

- 在 `ai-lib-go` 仓库单独发起版本治理任务：
  - 明确 semver 基线（是否以 v0.5.0 为起点）
  - 校准 tag/release/changelog 三者一致性
  - 回填 `ai-lib-plans/MEMORY.md` 历史记录，避免再次漂移
