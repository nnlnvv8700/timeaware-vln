# 模型与环境筛选建议

## 1. 环境选择

### 主推荐: GOAT-Bench language-goal 子集

为什么最适合你的题目:

- 它是 Habitat 上的 `multi-modal lifelong navigation` benchmark
- 一个 episode 包含 `5-10` 个顺序子任务，天然对应 `multi-target search`
- 论文里明确给每个 subtask 分配动作预算，天然支持 time-aware 分析
- 支持 `language description` 目标，不只是闭集 object category
- 重点讨论了 memory 在后续子任务上的收益，非常适合和 time budget 联合分析

推荐用法:

- 只取 `language-goal` 子任务
- 在同一 split 下比较不同模型
- 固定 success 判定与 stop 规则
- 扫描多个 `max_steps_per_subtask`

### 备选: MultiON

适合在以下情况下使用:

- 你更在意多目标导航链式完成率
- 你希望先在更简单、更封闭的目标定义上做实验
- 你暂时不想处理开放词汇语言描述

局限:

- 目标通常是 object category 序列，不是自然语言目标描述
- 更像 multi-object navigation，而不是强语言条件下的 search

## 2. 模型筛选

### A. VLN-CE CMA / Waypoint

定位:

- 经典、稳定、容易解释的 Habitat VLN 对照组

优点:

- 与 Habitat / VLN-CE 生态最贴近
- 适合做 classical baseline
- 可以回答“现代 VLM policy 比传统 VLN 强多少”

缺点:

- 主要面向 instruction-following，不是为 multi-target search 设计
- 迁移到 `GOAT-Bench language-goal` 需要目标提示与 stop 机制适配

结论:

- 建议保留，作为“老基线”

### B. IVLN-CE

定位:

- 最值得放进你的主对比组

优点:

- 明确研究 persistent environment over time
- 支持跨 tours 的 memory，对 time-aware 研究最有启发
- 很适合作为“是否引入显式/迭代记忆”对照

缺点:

- 仍然源自 R2R instruction-following 设定
- 代码栈偏旧，和新 Habitat 任务做统一时要写 adapter

结论:

- 强烈建议纳入

### C. NaVid

定位:

- 现代 video-based VLM baseline

优点:

- 不依赖 odometry / depth / map
- 对自然语言条件更友好
- 更接近 foundation-model 风格导航策略

缺点:

- 原始 benchmark 仍以 VLN-CE 为主
- 直接迁移到多目标搜索要做 prompt 与 success evaluator 适配

结论:

- 建议纳入，代表现代 VLM policy

### D. Uni-NaVid

定位:

- 强基线

优点:

- 统一 embodied navigation task
- 一般会比 NaVid 更适合做主结果表里的 strongest baseline

缺点:

- 资源需求较高
- 迁移成本与 NaVid 类似

结论:

- 建议纳入，作为强基线

### E. 可选扩展: LH-VLN

定位:

- 如果你后续想把研究从 “multi-target search” 扩展到 “long-horizon multi-stage VLN”，它很合适

优点:

- 天然多阶段、长时程
- 提供更接近规划与推理的 benchmark

缺点:

- 与 GOAT-Bench 的“目标搜索”范式不完全相同
- 更适合做后续扩展，而不是第一轮主实验

结论:

- 第二阶段再加

## 3. 最实用的实验组合

### 组合 A: 题目契合度优先

- env: `GOAT-Bench(language-only)`
- models: `IVLN-CE`, `NaVid`, `Uni-NaVid`, `VLN-CE CMA`

优点:

- 最贴近你的研究题目
- time-aware / multi-target / language 三个维度都保住了

代价:

- 需要自己写一层统一 adapter

### 组合 B: 工程风险优先

- env: `MultiON`
- models: `IVLN-CE`, `VLN-CE CMA`, `NaVid`

优点:

- 多目标链式完成统计更容易落地

代价:

- 语言条件弱化
- 更像 multi-object nav，而不是 language-conditioned search

## 4. 我建议的最终落地方案

第一轮主实验:

- `Env = GOAT-Bench language-goal`
- `Split = val_unseen`
- `Models = VLN-CE CMA, IVLN-CE, NaVid, Uni-NaVid`
- `Budgets = [100, 200, 300, 500]`

核心统计:

- `avg_completed_subtasks`
- `completion_rate = completed_subtasks / total_subtasks`
- `budget_auc`: 完成曲线下面积，衡量时间效率

如果你想马上把工程难度降下来:

- 先用 `MultiON` 跑通完整 pipeline
- 再切到 `GOAT-Bench language-only` 做正式结果

## 5. 主要参考链接

- VLN-CE: <https://github.com/jacobkrantz/VLN-CE>
- IVLN-CE: <https://github.com/jacobkrantz/IVLN-CE>
- NaVid / Uni-NaVid: <https://github.com/jzhzhang/NaVid-VLN-CE>
- GOAT-Bench paper: <https://openaccess.thecvf.com/content/CVPR2024/html/Khanna_GOAT-Bench_A_Benchmark_for_Multi-Modal_Lifelong_Navigation_CVPR_2024_paper.html>
- LH-VLN: <https://github.com/HCPLab-SYSU/LH-VLN>
