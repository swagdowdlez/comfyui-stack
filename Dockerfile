FROM nvidia/cuda:12.8.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV HF_HUB_ENABLE_HF_TRANSFER=1
ENV PATH="/workspace/comfy-env/bin:/workspace/miniforge3/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 wget bzip2 ffmpeg rsync ca-certificates curl tini \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

RUN wget -q -O /tmp/Miniforge3.sh https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh \
    && bash /tmp/Miniforge3.sh -b -p /workspace/miniforge3 \
    && rm /tmp/Miniforge3.sh

RUN /workspace/miniforge3/bin/conda create -y -p /workspace/comfy-env python=3.11 pip \
    && /workspace/comfy-env/bin/python -m pip install --upgrade pip setuptools wheel uv

RUN /workspace/comfy-env/bin/python -m uv pip install \
    torch==2.11.0+cu128 torchvision==0.26.0+cu128 torchaudio==2.11.0+cu128 \
    --index-url https://download.pytorch.org/whl/cu128

RUN git clone https://github.com/comfyanonymous/ComfyUI.git \
    && cd ComfyUI \
    && git checkout a5189fed515a96b71cf2b743fb93eaa3d42bc881

WORKDIR /workspace/ComfyUI
RUN /workspace/comfy-env/bin/python -m uv pip install -r requirements.txt \
    && /workspace/comfy-env/bin/python -m uv pip install \
        sqlalchemy==2.0.49 alembic==1.18.4 \
        "huggingface_hub[cli,hf_transfer]==1.14.0" hf_transfer hf-xet \
        transformers==5.8.1 diffusers \
        surrealist PyWavelets segment-anything iopath hydra-core \
        onnxruntime wget imageio-ffmpeg timm

WORKDIR /workspace/ComfyUI/custom_nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git \
    && cd ComfyUI-Manager \
    && git checkout 3b2f6fd149e582344f97f5536afa24f9a20bfb45 \
    && /workspace/comfy-env/bin/python -m uv pip install -r requirements.txt

RUN git clone https://github.com/Lightricks/ComfyUI-LTXVideo.git \
    && cd ComfyUI-LTXVideo \
    && git checkout 229437c6b65796d6a7a63ae34be2bd5ba31fa543 \
    && if [ -f requirements.txt ]; then /workspace/comfy-env/bin/python -m uv pip install -r requirements.txt; fi

RUN git clone https://github.com/un-seen/comfyui-tensorops.git \
    && cd comfyui-tensorops \
    && git checkout d34488e3079ecd10db2fe867c3a7af568115faed \
    && if [ -f requirements.txt ]; then /workspace/comfy-env/bin/python -m uv pip install -r requirements.txt; fi

RUN git clone https://github.com/ClownsharkBatwing/RES4LYF.git \
    && cd RES4LYF \
    && git checkout 1c9bf61792ba585ad2460c998f62ae75f7ca982b \
    && if [ -f requirements.txt ]; then /workspace/comfy-env/bin/python -m uv pip install -r requirements.txt; fi

WORKDIR /workspace/ComfyUI
RUN /workspace/comfy-env/bin/python custom_nodes/ComfyUI-Manager/cm-cli.py install \
    comfyui-itools@0.6.5 \
    comfyui-workflow-encrypt@1.0.0 \
    was-ns@3.0.1 \
    ComfyUI-Flux2Klein-Enhancer@3.3.1 \
    comfyui-rmbg@3.0.0 \
    comfyui_layerstyle@2.0.38 \
    rgthree-comfy@1.0.2605082257 \
    comfyui-videohelpersuite@1.7.9 \
    comfyui-kjnodes@1.4.0

RUN for d in /workspace/ComfyUI/custom_nodes/*/; do \
        if [ -f "$d/requirements.txt" ]; then \
            /workspace/comfy-env/bin/python -m uv pip install -r "$d/requirements.txt" || true; \
        fi; \
    done

RUN /workspace/comfy-env/bin/huggingface-cli login --token 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 --add-to-git-credential

RUN mkdir -p /workspace/ComfyUI/user /workspace/ComfyUI/output /workspace/ComfyUI/input

COPY start.sh /workspace/start.sh
RUN chmod +x /workspace/start.sh

EXPOSE 3001

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/workspace/start.sh"]
