#!/bin/bash

VOLUME=${1:-'./volume'}
ENGINE=docker

$ENGINE build --tag rocm-base - < Containerfile

mkdir -p "$VOLUME"
$ENGINE run -it --rm \
    --name rocm \
    --group-add video \
    --group-add render \
    --device /dev/kfd:/dev/kfd \
    --device /dev/dri:/dev/dri \
    -v "$VOLUME":/root/volume \
    -w "/root/volume/app" \
    \
    `# common` \
    -e VENV_DIR='/root/volume/environment/venv' \
    -e PYTORCH_REPO='https://download.pytorch.org/whl/nightly/rocm6.0' \
    -e PYTORCH_HIP_ALLOC_CONF='garbage_collection_threshold:0.9,max_split_size_mb:256' \
    -e HSA_OVERRIDE_GFX_VERSION='10.3.0' \
    \
    `# sdwebui` \
    -p 7860:7860 \
    -e SDWEBUI_NAME='sdwebui' \
    -e SDWEBUI_REPO='https://raw.githubusercontent.com/AUTOMATIC1111/stable-diffusion-webui/master/webui.sh' \
    -e SDWEBUI_ARGS='-f --listen --enable-insecure-extension-access --data-dir /root/volume/library --no-download-sd-model  --precision full --no-half --opt-sub-quad-attention' \
    -e SDWEBUI_INIT='
        curl -sSL -f "$SDWEBUI_REPO" | 
            clone_dir="$SDWEBUI_NAME" 
            venv_dir="$VENV_DIR" 
            TORCH_COMMAND="pip install --pre torch torchvision torchaudio --index-url \"$PYTORCH_REPO\""
            bash -s - $SDWEBUI_ARGS;
    ' \
    `# comfyui` \
    -p 8188:8188 \
    -e COMFYUI_NAME='comfyui' \
    -e COMFYUI_REPO='https://github.com/comfyanonymous/ComfyUI' \
    -e COMFYUI_ARGS='--listen 0.0.0.0 --disable-auto-launch --dont-upcast-attention `#--force-fp16` `#--fp16-vae` `#--fp32-vae` `#--cpu-vae` `#--lowvram`' \
    -e COMFYUI_INIT='
        if [ ! -e "$COMFYUI_NAME" ]; then
            git clone --depth 1 "$COMFYUI_REPO" "$COMFYUI_NAME";
        fi;
        cd "$COMFYUI_NAME";
        python3 -m venv "$VENV_DIR";
        pip install --pre torch torchvision torchaudio --index-url "$PYTORCH_REPO";
        pip install -r requirements.txt;
        python3 main.py $COMFYUI_ARGS;
    ' \
    \
    rocm-base \
    bash -c 'eval $COMFYUI_INIT'
