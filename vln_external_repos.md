# External Repositories

This project keeps third-party VLN benchmark code out of the root GitHub repo to avoid vendoring large nested repositories and dataset artifacts. Clone or restore these repositories under `vln_external/` before running the benchmark scripts.

| Path | Remote | Commit used locally | Notes |
|---|---|---:|---|
| `vln_external/VLN-CE` | `https://github.com/jacobkrantz/VLN-CE.git` | `729d141` | Native VLN-CE baseline code. |
| `vln_external/IVLN-CE` | `https://github.com/jacobkrantz/IVLN-CE.git` | `14417fc` | IVLN-CE baseline code. |
| `vln_external/goat-bench` | `https://github.com/Ram81/goat-bench.git` | `74c41d1` | Apply `patches/goat-bench-local-fixes.patch` after cloning. |
| `vln_external/NaVILA` | `https://github.com/AnjieCheng/NaVILA.git` | `76b98f2` | Future VLM baseline candidate. |
| `vln_external/Uni-NaVid` | `https://github.com/jzhzhang/Uni-NaVid.git` | `79ef5ea` | Future VLM baseline candidate. |
| `vln_external/StreamVLN` | `https://github.com/OpenRobotLab/StreamVLN.git` | `e48f6ff` | Future VLM baseline candidate. |

Example restore flow:

```bash
mkdir -p vln_external

git clone https://github.com/Ram81/goat-bench.git vln_external/goat-bench
cd vln_external/goat-bench
git checkout 74c41d1
git apply ../../patches/goat-bench-local-fixes.patch
cd ../..
```

Large datasets and checkpoints are intentionally not tracked. See `README.md` for the current local data status and required paths.
