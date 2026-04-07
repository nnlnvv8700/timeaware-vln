FROM nvidia/cuda:11.3.1-cudnn8-runtime-ubuntu20.04

ARG DEBIAN_FRONTEND=noninteractive
ARG MAMBA_ROOT_PREFIX=/opt/conda
ENV MAMBA_ROOT_PREFIX=${MAMBA_ROOT_PREFIX}
ENV PATH=${MAMBA_ROOT_PREFIX}/envs/goat/bin:${MAMBA_ROOT_PREFIX}/bin:/usr/local/bin:/usr/bin:/bin
ENV GLOG_minloglevel=2
ENV MAGNUM_LOG=quiet
ENV HABITAT_SIM_LOG=quiet
ENV PYTHONUNBUFFERED=1

SHELL ["/bin/bash", "-lc"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    build-essential \
    ca-certificates \
    curl \
    git \
    libegl1 \
    libgl1 \
    libglib2.0-0 \
    libglvnd0 \
    libglx0 \
    libjpeg-dev \
    libomp5 \
    libpng-dev \
    libsm6 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    unzip \
    vim \
    wget \
    zip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest \
    | tar -xvj -C /usr/local/bin --strip-components=1 bin/micromamba

RUN micromamba create -y -n goat \
    -c pytorch \
    -c nvidia \
    -c conda-forge \
    -c aihabitat \
    python=3.7 \
    cmake=3.14.0 \
    habitat-sim=0.2.3 \
    headless \
    pytorch \
    cudatoolkit=11.3 \
    && micromamba clean -a -y

RUN micromamba install -y -n goat \
    -c conda-forge \
    "mkl<2024" \
    "mkl-devel<2024" \
    "mkl-include<2024" \
    && micromamba clean -a -y

RUN python -m pip install --no-cache-dir --upgrade "pip<24" "setuptools<60" wheel

RUN git clone --depth 1 --branch v0.2.3 https://github.com/facebookresearch/habitat-lab.git /opt/habitat-lab \
    && python -m pip install --no-cache-dir -e /opt/habitat-lab/habitat-lab \
    && python -m pip install --no-cache-dir -e /opt/habitat-lab/habitat-baselines

RUN python -m pip install --no-cache-dir --force-reinstall \
    cffi==1.15.1 \
    lmdb==1.3.0

RUN python -m pip install --no-cache-dir \
    ftfy==6.1.1 \
    regex==2024.4.16 \
    GPUtil==1.4.0 \
    trimesh==4.4.1 \
    seaborn==0.12.2 \
    timm==0.4.12 \
    scikit-learn==1.0.2 \
    einops==0.6.1 \
    transformers==4.26.1 \
    openai==0.27.8 \
    open3d==0.17.0 \
    torchvision==0.14.1

RUN for attempt in 1 2 3; do \
      git clone --depth 1 https://github.com/openai/CLIP.git /opt/CLIP && break; \
      rm -rf /opt/CLIP; \
      echo "Retrying CLIP clone (${attempt}/3)"; \
      sleep 5; \
    done \
    && test -d /opt/CLIP/.git \
    && python -m pip install --no-cache-dir -e /opt/CLIP

RUN apt-get update && apt-get install -y --no-install-recommends \
    libopengl0 \
    iproute2 \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

ENV PATH=${MAMBA_ROOT_PREFIX}/envs/goat/bin:${MAMBA_ROOT_PREFIX}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /all_vln/vln/vln_external/goat-bench
CMD ["bash"]
