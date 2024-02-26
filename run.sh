#!/bin/sh

podman build --tag rocm-base - < Containerfile

DIR=./app
mkdir -p "$DIR"
podman run -it --rm \
    --name rocm \
    --group-add video \
    --group-add render \
    --device /dev/kfd:/dev/kfd \
    --device /dev/dri:/dev/dri \
    -v "$DIR":/root/app \
    -w /root/app \
    -p 7860:7860 \
    -e PYTORCH_HIP_ALLOC_CONF="garbage_collection_threshold:0.9,max_split_size_mb:256" \
    -e HSA_OVERRIDE_GFX_VERSION="10.3.0" \
    -e venv_dir=../venv \
    -e TORCH_COMMAND="pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm5.7" \
    -e COMMANDLINE_ARGS="-f --data-dir --listen --enable-insecure-extension-access --no-download-sd-model --precision full --no-half --opt-sub-quad-attention" \
    rocm-base \
    bash -c "wget -q --no-hsts https://raw.githubusercontent.com/AUTOMATIC1111/stable-diffusion-webui/master/webui.sh -O - | bash -s - -f"
