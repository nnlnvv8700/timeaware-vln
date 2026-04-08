# Time-aware VLN for Multi-target Search

这个工作区是一个面向 `Habitat` 的小型 research scaffold，用来做:

- 多个开源 `Vision-Language Navigation` / language-conditioned navigation 模型筛选
- 同一多目标 Habitat 环境下的统一评测
- 在不同时间步长预算下统计各模型完成的子任务数量
- 输出可复现实验表格与可视化图

## 推荐结论

主推荐环境:

- `GOAT-Bench` 的 `language-goal` 子集

原因:

- 原生是 `Habitat` 上的多目标序列任务
- 每个 episode 包含 `5-10` 个连续子任务
- 每个子任务有明确时间预算
- 支持 `language / image / object` 多模态目标，其中 `language` 子集最贴近你的题目
- 研究重点天然包含 `memory` 与 `time budget`

备选环境:

- `MultiON`

适用场景:

- 如果你更想先低成本验证“多目标搜索 + 时间预算”而不是开放词汇语言目标
- 但它是闭集类别目标，语言表达能力弱于 `GOAT-Bench`

## GOAT / TimeAwareVLN 容器环境

当前本机已新建并跑通过 GOAT 实验容器:

- Docker image: `timeawarevln-goat:0.1`
- Python: `3.7.12`
- PyTorch: `1.13.1`
- `torch.cuda.is_available()`: `True`
- `habitat`: `0.2.3`
- `habitat_sim`: `0.2.3`
- `goat_bench` 可正常 import

相关脚本:

- `docker/goat.Dockerfile`
- `scripts/docker_build_goat.sh`
- `scripts/docker_run_goat.sh`
- `scripts/check_goat_data.sh`
- `scripts/summarize_goat_budget_sweep.sh`

常用验证命令:

```bash
./scripts/docker_run_goat.sh python --version
./scripts/docker_run_goat.sh python -c "import torch; print('torch', torch.__version__, torch.cuda.is_available())"
./scripts/docker_run_goat.sh python -c "import habitat; import habitat_sim; print('ok')"
./scripts/docker_run_goat.sh python -c "import goat_bench; print('goat_bench import ok')"
./scripts/check_goat_data.sh
```

运行 1 个 episode 的 GOAT monolithic smoke eval:

```bash
./scripts/run_goat_smoke_eval.sh
```

扩大评测集:

```bash
TEST_EPISODE_COUNT=10 ./scripts/run_goat_smoke_eval.sh
```

运行多个 step budget:

```bash
TEST_EPISODE_COUNT=100 BUDGETS="100 200 300 500" ./scripts/run_goat_budget_sweep.sh
```

把 GOAT `episode_metrics.json` 聚合成 budget summary CSV:

```bash
TEST_EPISODE_COUNT=100 UPDATE_DEFAULT=1 ./scripts/summarize_goat_budget_sweep.sh
```

如果要手动指定输出，也可以直接调用底层脚本:

```bash
python3 scripts/goat_metrics_to_budget_summary.py \
  --input 100=vln_external/goat-bench/data/tb/smoke_val_unseen_100_budget_100/episode_metrics.json \
  --input 200=vln_external/goat-bench/data/tb/smoke_val_unseen_100_budget_200/episode_metrics.json \
  --input 300=vln_external/goat-bench/data/tb/smoke_val_unseen_100_budget_300/episode_metrics.json \
  --input 500=vln_external/goat-bench/data/tb/smoke_val_unseen_100_budget_500/episode_metrics.json \
  --output results/goat_senseact_nn_budget_summary.csv
```

当前已生成一版 100-episode smoke 结果，并把它作为默认展示结果:

- `results/goat_senseact_nn_budget_summary.csv`
- `figures/goat_senseact_nn_budget_vs_completion.svg`

同时保留了 10-episode 小样本副本:

- `results/goat_senseact_nn_budget_summary_10eps.csv`
- `figures/goat_senseact_nn_budget_vs_completion_10eps.svg`

100-episode 版本依然属于 smoke eval，不是完整 `val_unseen` 最终数值。本地 `val_unseen` 一共有 `360` 个 episodes，更稳定的下一步是跑完整 split:

```bash
TEST_EPISODE_COUNT=360 BUDGETS="100 200 300 500" ./scripts/run_goat_budget_sweep.sh
```

当前 GOAT 评测数据已补齐并通过 `scripts/check_goat_data.sh`:

- HM3D val 场景位于 `vln_external/goat-bench/data/scene_datasets/hm3d/`
- GOAT-Bench episodes 位于 `vln_external/goat-bench/data/datasets/goat_bench/hm3d/v1/`

`goat-assets` 已经放在 `vln_external/goat-bench/data/goat-assets/`，其中 monolithic checkpoint 与 language/object/image goal cache 已通过 `scripts/check_goat_data.sh` 检查。

## VLN-CE / IVLN-CE 容器与数据进度

当前本机已新建并跑通过 VLN-CE / IVLN-CE 共用实验容器:

- Docker image: `timeawarevln-vlnce:0.1`
- Python: `3.6.15`
- PyTorch: `1.10.2+cu113`
- `torch.cuda.is_available()`: `True`
- `habitat`: `0.1.7`
- `habitat_sim`: `0.1.7`
- `vlnce_baselines` 可正常 import
- `ivlnce_baselines` / `habitat_extensions` 可正常 import

相关脚本:

- `docker/vlnce.Dockerfile`
- `scripts/docker_build_vlnce.sh`
- `scripts/docker_run_vlnce.sh`
- `scripts/check_native_baselines_data.sh`
- `scripts/install_mp3d_scenes.sh`
- `scripts/run_vlnce_cma_smoke_eval.sh`
- `scripts/run_ivlnce_mapcma_smoke_eval.sh`
- `scripts/prefetch_vlnce_wheels.sh`
- `scripts/download_file_segments.py`

GitHub 仓库不会直接追踪 `vln_external/`、数据集、checkpoint 或本地 wheel 缓存。外部仓库 URL、当前 commit 和本地 `goat-bench` patch 见:

- `vln_external_repos.md`
- `patches/goat-bench-local-fixes.patch`

这次构建中遇到的主要问题是旧版 Py3.6 环境依赖和外部下载不稳定:

- `torch-1.10.2+cu113` wheel 约 `1.82GB`，Docker 内部单连接 `pip` 下载会长时间无输出且速度逐渐变慢。
- 已改为先用 `scripts/download_file_segments.py` 多线程 HTTP Range 断点下载到 `docker/wheels/`，再在 Docker 内从本地 wheel 安装。
- 当前本地已缓存这些 wheel:
  - `docker/wheels/torch-1.10.2+cu113-cp36-cp36m-linux_x86_64.whl`
  - `docker/wheels/torchvision-0.11.3+cu113-cp36-cp36m-linux_x86_64.whl`
  - `docker/wheels/torch_scatter-2.0.9-cp36-cp36m-linux_x86_64.whl`
  - `docker/wheels/tensorflow-1.13.1-cp36-cp36m-manylinux1_x86_64.whl`
- `docker/vlnce.Dockerfile` 里增加了 Py3.6 兼容约束，避免 `pip` 拉到过新的 `opencv-python`, `lmdb`, `protobuf` 等包。
- `libOpenGL.so.0` 缺失已通过 `libopengl0` 修复。
- `torch.utils.tensorboard` 要求 `tensorboard>=1.15`，已把 TensorBoard 调整为 `1.15.0`。
- `.dockerignore` 已排除 `docker/wheels/*.parts/`，避免分段下载临时分片进入 build context。

常用验证命令:

```bash
./scripts/docker_run_vlnce.sh python --version
./scripts/docker_run_vlnce.sh python -c "import torch; print('torch', torch.__version__, torch.cuda.is_available())"
./scripts/docker_run_vlnce.sh python -c "import habitat, habitat_sim; print('habitat ok', getattr(habitat, '__version__', 'unknown')); print('habitat_sim ok')"
./scripts/docker_run_vlnce.sh bash -lc 'cd /all_vln/vln/vln_external/VLN-CE && python -c "import vlnce_baselines; print(\"vlnce ok\")"'
./scripts/docker_run_vlnce.sh bash -lc 'cd /all_vln/vln/vln_external/IVLN-CE && python -c "import ivlnce_baselines; import habitat_extensions; print(\"ivln ok\")"'
```

如果需要重新构建:

```bash
./scripts/docker_build_vlnce.sh
```

`scripts/docker_build_vlnce.sh` 会先调用 `scripts/prefetch_vlnce_wheels.sh`。默认使用官方源，如果官方源不稳定，可以临时切换 PyTorch wheel 源:

```bash
VLNCE_WHEEL_SOURCE=aliyun CONNECTIONS=8 ./scripts/prefetch_vlnce_wheels.sh
VLNCE_WHEEL_SOURCE=official CONNECTIONS=8 ./scripts/prefetch_vlnce_wheels.sh
```

当前 VLN-CE / IVLN-CE 数据和权重状态:

- VLN-CE R2R preprocessed dataset 已放好:
  - `vln_external/VLN-CE/data/datasets/R2R_VLNCE_v1-3_preprocessed/`
- VLN-CE `val_unseen` episodes 已放好:
  - `vln_external/VLN-CE/data/datasets/R2R_VLNCE_v1-3_preprocessed/val_unseen/val_unseen.json.gz`
- VLN-CE CMA checkpoint 已放好:
  - `vln_external/VLN-CE/data/checkpoints/CMA_PM_DA_Aug.pth`
- DD-PPO depth encoder 已放好，并在 IVLN-CE 中复用:
  - `vln_external/VLN-CE/data/ddppo-models/gibson-2plus-resnet50.pth`
  - `vln_external/IVLN-CE/data/ddppo-models/gibson-2plus-resnet50.pth`
- IVLN-CE 需要的 `tours.json` 和 `gt_ndtw.json` 已放好:
  - `vln_external/IVLN-CE/data/tours.json`
  - `vln_external/IVLN-CE/data/gt_ndtw.json`
- IVLN MapCMA checkpoints 已放好，`pretrained_mapcma/` 下有 6 个 `.pth`:
  - `vln_external/IVLN-CE/data/checkpoints/pretrained_mapcma/`

当前仍缺 MP3D scene data，因此 VLN-CE / IVLN-CE 还不能正式跑 benchmark:

- `vln_external/VLN-CE/data/scene_datasets/mp3d/`
- `vln_external/IVLN-CE/data/scene_datasets/mp3d/`

MP3D 的阻塞点不是仓库代码，而是 `Matterport3D` 官方授权:

- 需要先到 Matterport 官方页面按条款申请访问权限
- 拿到官方 `download_mp.py` 后，用 `python2.7` 下载 `--task habitat`
- 本仓库已经补了 `scripts/install_mp3d_scenes.sh`，可以把这一步变成统一缓存 + 双项目链接

如果你已经有现成的 MP3D 目录:

```bash
./scripts/install_mp3d_scenes.sh --source /path/to/mp3d
```

如果你拿到了官方 `download_mp.py`:

```bash
./scripts/install_mp3d_scenes.sh --download-script /path/to/download_mp.py
```

默认会把共享场景放到:

- `data/scene_datasets/mp3d/`

然后把下面两个路径做成符号链接:

- `vln_external/VLN-CE/data/scene_datasets/mp3d`
- `vln_external/IVLN-CE/data/scene_datasets/mp3d`

用下面命令检查数据是否补齐:

```bash
./scripts/check_native_baselines_data.sh
```

当前检查结果是除 MP3D scenes 外，其余 R2R 数据、checkpoints、IVLN `tours.json` / `gt_ndtw.json` 都是 `ok`。一旦 MP3D 补齐，就可以直接开始 smoke eval:

```bash
EVAL_EPISODE_COUNT=10 ./scripts/run_vlnce_cma_smoke_eval.sh
EVAL_EPISODE_COUNT=10 ./scripts/run_ivlnce_mapcma_smoke_eval.sh
```

## 建议优先比较的模型

推荐先做 4 个模型:

1. `VLN-CE CMA / Waypoint`  
   经典 Habitat 原生基线，适合作为可复现对照组。
2. `IVLN-CE`  
   显式面向 persistent environment over time，最适合做 time-aware / memory-aware 对照。
3. `NaVid`  
   视频式 VLM policy，不依赖 odometry / depth / map，适合作为现代 VLM baseline。
4. `Uni-NaVid`  
   比 `NaVid` 更强的统一 embodied navigation 模型，可作为强基线。

更详细的筛选理由见 [docs/model_env_recommendation.md](docs/model_env_recommendation.md)。

## 统一评测协议

建议先固定:

- split: `val_unseen`
- modality: `language`
- budgets: `100, 200, 300, 500`
- 主要指标: `avg_completed_subtasks`
- 辅助指标: `completion_rate`, `budget_auc`

结果文件格式见 [configs/benchmark_goat_lang.yaml](configs/benchmark_goat_lang.yaml) 和 [results/example_budget_summary.csv](results/example_budget_summary.csv)。

如果你拿到的是逐 episode 原始结果，先聚合:

```bash
python3 scripts/summarize_episode_results.py \
  --input results/template_episode_results.csv \
  --output results/from_episode_summary.csv
```

## 可视化

运行:

```bash
python3 scripts/plot_budget_vs_completion.py \
  --input results/example_budget_summary.csv \
  --output figures/example_budget_vs_completion.svg
```

输出图:

- [figures/example_budget_vs_completion.svg](figures/example_budget_vs_completion.svg)

注意:

- `example_*` / `template_*` 文件是 `mock example`，用于说明实验管线与画图方式，不代表真实模型成绩。
- `goat_senseact_nn_*` 文件来自本机 GOAT smoke eval，当前默认结果是 100 个 episode。
- 你后面只要把更大规模真实评测结果按同样 schema 写成 CSV，就可以直接复用。
