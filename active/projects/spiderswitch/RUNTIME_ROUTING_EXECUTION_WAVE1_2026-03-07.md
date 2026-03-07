# spiderswitch Runtime Routing 编码执行 Wave-1（2026-03-07）

## 范围

本波次完成 `MS-005` / `MS-006` / `MS-007` 的最小可用代码闭环，聚焦：

1. runtime-neutral capability schema  
2. RuntimeRegistry/Resolver 执行层  
3. runtime_id 维度的工具契约与状态语义  
4. 跨运行时契约测试基线

## 代码交付

### 1) Capability Schema（MS-005）

- 扩展 `RuntimeProfile`：
  - `model_capabilities`
  - `runtime_capabilities`
  - `operational_metrics`
  - `reserved_runtimes`（预留 Go/WASM）
- 统一序列化方法：`RuntimeProfile.to_dict()`

### 2) Registry/Resolver 执行层（MS-006）

- 新增 `src/spiderswitch/runtime/registry.py`
  - `RuntimeRegistry`
  - `RuntimeResolver`
  - `RuntimeResolution`
- `server.py` 接入 runtime 解析逻辑：
  - `switch_model` / `list_models` / `get_status` / `exit_switcher` 支持 `runtime_id`
  - 未指定 runtime_id 时按 `request -> state -> default` 解析顺序
- `state.py` 增加 runtime 维度：
  - `runtime_id`
  - `runtime_epoch`
  - `runtime_epochs`
  - `reset(scope=runtime/all)` 的 epoch 协调语义

### 3) 工具契约升级（MS-006 / MS-007）

- `switch_model` / `list_models` / `get_status` 入参新增 `runtime_id`
- `exit_switcher` 入参新增：
  - `runtime_id`
  - `scope`（`all`/`runtime`）
- 响应中的 `runtime_profile` 统一由 `to_dict()` 输出

### 4) 契约测试矩阵基线（MS-007）

- 新增 `tests/test_runtime_registry.py`：
  - runtime 注册/解析
  - request/state/default 优先级断言
- 更新 `tests/test_server_regression.py`：
  - runtime-aware 状态路径
  - runtime scope reset 行为断言
- 更新 `tests/test_state.py` / `tests/test_tools.py` / `tests/test_runtime.py`
  - runtime schema 字段断言
  - runtime epoch 与 scoped reset 断言

## 验证结果

- `python -m pytest`
  - `32 passed`

## 边界说明

- spiderswitch 仍只提供“路由执行能力 + 能力信号”，不承载策略引擎。
- runtime 选择策略（成本、质量、租户规则）继续由上层应用负责。
