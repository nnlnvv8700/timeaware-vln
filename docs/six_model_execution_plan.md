# 六模型实验落地路线图

目标：

- 环境固定为 `Habitat + GOAT-Bench(language-goal)`
- 模型对比为：
  - `GOAT-Bench` 原生 baseline
  - `Waypoint`
  - `IVLN-CE`
  - `StreamVLN`
  - `Uni-NaVid`
  - `NaVILA`
- 比较不同 `time budget` 下各模型完成的 `subtask` 数量

## 先说最关键的结论

不要试图把 6 个模型塞进同一个 conda 环境。

原因：

- `GOAT-Bench` 原生代码依赖 `Habitat 0.2.3`
- `StreamVLN` 官方测试环境依赖 `Habitat 0.2.4`
- `Waypoint / IVLN-CE / Uni-NaVid / NaVILA` 基本都沿着 `VLN-CE 0.1.7` 旧栈
- `NaVILA` 还叠加了 `VILA / FlashAttention / transformers hotfix`

正确做法：

- 每个模型先在自己的原生环境里跑通
- 用统一的结果 schema 做汇总
- 最后再做 “同一 GOAT 环境” 的 adapter 和统一评测

## 推荐目录结构

建议在工作区外再建一个 `third_party` 或 `external` 目录：

```text
/home/mhw/
├── vln/
│   ├── docs/
│   ├── configs/
│   ├── results/
│   ├── figures/
│   └── scripts/
└── vln_external/
    ├── goat-bench/
    ├── VLN-CE/
    ├── IVLN-CE/
    ├── StreamVLN/
    ├── NaVid-VLN-CE/
    └── NaVILA/
```

## 第一阶段：把原生环境都跑通

### 1. GOAT-Bench 原生 baseline

用途：

- 这是你的任务原生基线
- 也是后面统一评测的主环境

需要的数据：

- `HM3D`
- `GOAT-Bench episodes`
- `goal caches / checkpoints`

建议 conda 环境：

- `goat_env`

### 2. Waypoint

用途：

- 经典 `VLN-CE` 强基线

需要的数据：

- `MP3D`
- `R2R_VLNCE`

建议 conda 环境：

- `vlnce_env`

### 3. IVLN-CE

用途：

- time-aware / persistent environment 基线

需要的数据：

- `MP3D`
- `R2R_VLNCE`
- `IR2R tours / ndtw files`

建议 conda 环境：

- `ivln_env`

### 4. StreamVLN

用途：

- 较新的 streaming memory / low-latency VLN 基线

需要的数据：

- 官方主要支持 `R2R / RxR / EnvDrop / ScaleVLN`
- 你至少先准备 `R2R` 做原生 sanity check

建议 conda 环境：

- `streamvln_env`

### 5. Uni-NaVid

用途：

- 统一 embodied navigation 强基线

需要的数据：

- `MP3D`
- `R2R_VLNCE / RxR_VLNCE`

建议 conda 环境：

- `uninavid_env`

### 6. NaVILA

用途：

- 更新一代 VLA 导航基线

需要的数据：

- `MP3D`
- `R2R_VLNCE / RxR_VLNCE`

建议 conda 环境：

- `navila_env`

## 第二阶段：不要急着“同 env”，先做 native sanity check

每个模型先完成 3 件事：

1. 能在官方推荐数据上跑通一次 `eval`
2. 能拿到官方输出的 `json / log / score`
3. 能把结果转成统一 csv schema

只有这一步都完成，后面统一到 `GOAT-Bench` 才不会乱。

## 第三阶段：统一结果 schema

你最终只需要一种公共格式：

```csv
model,budget_steps,split,episode_id,completed_subtasks,total_subtasks
```

如果原始模型输出不是这个格式，就写 adapter 转换。

仓库里已经有：

- `results/template_episode_results.csv`
- `scripts/summarize_episode_results.py`
- `scripts/plot_budget_vs_completion.py`

## 第四阶段：真正困难的地方

真正难点不是画图，而是：

- 除了 `GOAT-Bench` 原生 baseline，其它 5 个模型都不是原生为 `GOAT language multi-target search` 写的

这意味着你需要一个统一评测 adapter。

## 第五阶段：统一 GOAT adapter 的最小设计

建议先只做 `language-goal` 子任务，不碰 image-goal / object-goal。

### 输入统一

给每个模型的当前输入统一为：

- 当前 RGB / depth / pose
- 当前语言目标描述
- 当前 subtask 剩余 budget
- 历史 memory（如果模型支持）

### 输出统一

每步只允许输出：

- `MOVE_FORWARD`
- `TURN_LEFT`
- `TURN_RIGHT`
- `LOOK_UP`
- `LOOK_DOWN`
- `STOP`

### 成功判定统一

- `STOP` 且距离目标实例 `<= 1m`

### 预算统一

- 每个 subtask 分别跑 `100 / 200 / 300 / 500` steps

## 第六阶段：推荐的实际执行顺序

这个顺序最稳：

1. 跑通 `GOAT-Bench` 原生 baseline
2. 跑通 `Waypoint`
3. 跑通 `IVLN-CE`
4. 写统一结果转换脚本
5. 先把 `Waypoint` 迁移进 `GOAT language-only`
6. 再迁移 `IVLN-CE`
7. 再尝试 `StreamVLN`
8. 最后做 `Uni-NaVid` 和 `NaVILA`

原因：

- `Waypoint` 和 `IVLN-CE` 更容易理解和控制
- `StreamVLN / Uni-NaVid / NaVILA` 依赖更重、推理链更长、debug 成本更高

## 第七阶段：我建议你本周先完成的内容

### Day 1

- 建外部代码目录
- clone 6 个仓库
- 整理所有 checkpoint 和数据下载链接

### Day 2

- 跑通 `GOAT-Bench` 原生 baseline 的一次 evaluation

### Day 3

- 跑通 `Waypoint` 的一次 evaluation

### Day 4

- 跑通 `IVLN-CE` 的一次 evaluation

### Day 5

- 写 `native result -> unified csv` 的转换器
- 先把 3 个模型的结果画成一张图

## 第八阶段：最重要的风险

### 风险 1

- 六个模型的 Habitat 版本不一致

解决：

- 每个模型单独 conda env

### 风险 2

- 非 GOAT 模型不能直接理解多目标 sequential search

解决：

- 先只喂当前 subtask 的 language goal
- 每个 subtask 结束后再刷新下一个 goal

### 风险 3

- 不同模型对 `STOP` 的使用方式不同

解决：

- 统一用 GOAT 的 success checker
- 不改 success definition，只改模型输入适配

### 风险 4

- `NaVILA` 和 `StreamVLN` 很吃显存

解决：

- 先做最小 evaluation，不先训练

## 一句话执行建议

第一步不是同时做 6 个模型，而是：

- `先跑 GOAT baseline`
- `再跑 Waypoint`
- `再跑 IVLN-CE`

这 3 个一旦跑通，你的实验主线就立住了。
