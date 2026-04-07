FROM nvidia/cuda:11.3.1-cudnn8-runtime-ubuntu20.04

ARG DEBIAN_FRONTEND=noninteractive
ARG MAMBA_ROOT_PREFIX=/opt/conda
ENV MAMBA_ROOT_PREFIX=${MAMBA_ROOT_PREFIX}
ENV PATH=${MAMBA_ROOT_PREFIX}/envs/vlnce/bin:${MAMBA_ROOT_PREFIX}/bin:/usr/local/bin:/usr/bin:/bin
ENV PYTHONUNBUFFERED=1
ENV GLOG_minloglevel=2
ENV MAGNUM_LOG=quiet
ENV HABITAT_SIM_LOG=quiet

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
    libopengl0 \
    libpng-dev \
    libsm6 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    unzip \
    wget \
    zip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest \
    | tar -xvj -C /usr/local/bin --strip-components=1 bin/micromamba

RUN micromamba create -y -n vlnce \
    -c aihabitat \
    -c conda-forge \
    python=3.6 \
    habitat-sim=0.1.7 \
    headless \
    && micromamba clean -a -y

RUN python -m pip install --no-cache-dir --upgrade "pip<22" "setuptools<60" wheel \
    && python -m pip install --no-cache-dir \
    dataclasses \
    typing-extensions

RUN printf '%s\n' \
    'attrs==21.4.0' \
    'gym==0.21.0' \
    'ifcfg==0.22' \
    'imageio==2.15.0' \
    'imageio-ffmpeg==0.4.5' \
    'gdown==4.4.0' \
    'jsonlines==3.0.0' \
    'lmdb==1.3.0' \
    'matplotlib==3.3.4' \
    'moviepy==1.0.3' \
    'msgpack-numpy==0.4.7.1' \
    'networkx==2.5.1' \
    'numba==0.53.1' \
    'numpy==1.19.5' \
    'numpy-quaternion==2021.8.30.10.33.11' \
    'opencv-python==4.5.5.64' \
    'pillow==8.4.0' \
    'protobuf==3.19.6' \
    'scipy==1.5.3' \
    'tqdm==4.63.1' \
    'yacs==0.1.8' \
    > /tmp/vlnce-py36-constraints.txt

COPY docker/wheels/ /tmp/vlnce-wheels/

RUN python -m pip install --no-cache-dir --no-index --no-deps --find-links /tmp/vlnce-wheels \
    torch==1.10.2+cu113 \
    torchvision==0.11.3+cu113

RUN python -m pip install --no-cache-dir --no-index --no-deps --find-links /tmp/vlnce-wheels \
    torch-scatter==2.0.9

RUN git clone --depth 1 --branch v0.1.7 https://github.com/facebookresearch/habitat-lab.git /opt/habitat-lab \
    && grep -v -E '^(tensorflow|tb-nightly)([=<>!]|$)' /opt/habitat-lab/requirements.txt > /tmp/habitat-lab-requirements-filtered.txt \
    && grep -v -E '^(tensorflow|tb-nightly)([=<>!]|$)' /opt/habitat-lab/habitat_baselines/rl/requirements.txt > /tmp/habitat-baselines-rl-requirements-filtered.txt \
    && grep -v -E '^(tensorflow|tb-nightly)([=<>!]|$)' /opt/habitat-lab/habitat_baselines/rl/ddppo/requirements.txt > /tmp/habitat-ddppo-requirements-filtered.txt \
    && python -m pip install --no-cache-dir --retries 20 --timeout 120 -c /tmp/vlnce-py36-constraints.txt -r /tmp/habitat-lab-requirements-filtered.txt \
    && python -m pip install --no-cache-dir --retries 20 --timeout 120 -c /tmp/vlnce-py36-constraints.txt -r /tmp/habitat-baselines-rl-requirements-filtered.txt \
    && python -m pip install --no-cache-dir --retries 20 --timeout 120 -c /tmp/vlnce-py36-constraints.txt -r /tmp/habitat-ddppo-requirements-filtered.txt \
    && python -m pip install --no-cache-dir --retries 20 --timeout 120 -e /opt/habitat-lab

COPY vln_external/VLN-CE/requirements.txt /tmp/vlnce-requirements.txt
COPY vln_external/IVLN-CE/requirements.txt /tmp/ivlnce-requirements.txt

RUN grep -v -E '^(torch|torchvision|torch-scatter|tensorflow|tb-nightly|pre-commit)([=<>!]|$)' /tmp/vlnce-requirements.txt > /tmp/vlnce-requirements-filtered.txt \
    && grep -v -E '^(torch|torchvision|torch-scatter|tensorflow|tb-nightly|pre-commit)([=<>!]|$)' /tmp/ivlnce-requirements.txt > /tmp/ivlnce-requirements-filtered.txt \
    && python -m pip install --no-cache-dir --retries 20 --timeout 120 -c /tmp/vlnce-py36-constraints.txt -r /tmp/vlnce-requirements-filtered.txt \
    && python -m pip install --no-cache-dir --retries 20 --timeout 120 -c /tmp/vlnce-py36-constraints.txt -r /tmp/ivlnce-requirements-filtered.txt \
    && python -m pip install --no-cache-dir --retries 20 --timeout 120 -c /tmp/vlnce-py36-constraints.txt \
    absl-py==0.15.0 \
    astor==0.8.1 \
    gast==0.2.2 \
    grpcio==1.48.2 \
    keras-applications==1.0.8 \
    keras-preprocessing==1.1.2 \
    protobuf==3.19.6 \
    tensorboard==1.15.0 \
    tensorflow-estimator==1.13.0 \
    termcolor==1.1.0 \
    && python -m pip install --no-cache-dir --no-index --no-deps --find-links /tmp/vlnce-wheels tensorflow==1.13.1

ENV PYTHONPATH=/all_vln/vln/vln_external/VLN-CE:/all_vln/vln/vln_external/IVLN-CE
ENV PATH=${PATH}:/usr/sbin:/sbin

WORKDIR /all_vln/vln
CMD ["bash"]
