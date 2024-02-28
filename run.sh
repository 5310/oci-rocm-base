#!/bin/bash

ENGINE=podman
VOLUME=${1:-./volume}

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
    -e REPO_PYTORCH='https://download.pytorch.org/whl/nightly/rocm6.0' \
    -e PYTORCH_HIP_ALLOC_CONF='garbage_collection_threshold:0.9,max_split_size_mb:256' \
    -e HSA_OVERRIDE_GFX_VERSION='10.3.0' \
    \
    `# sdwebui` \
    -p 7860:7860 \
    -e ID_SDWEBUI='sdwebui' \
    -e REPO_SDWEBUI='https://raw.githubusercontent.com/AUTOMATIC1111/stable-diffusion-webui/master/webui.sh' \
    -e LAUNCH_SDWEBUI='
        curl -sSL -f "$REPO_SDWEBUI" | 
            clone_dir="$ID_SDWEBUI" 
            venv_dir="$VENV_DIR" 
            TORCH_COMMAND="pip install --pre torch torchvision torchaudio --index-url \"$REPO_PYTORCH\""
            bash -s - -f --listen --enable-insecure-extension-access --data-dir /root/volume/library --no-download-sd-model  --precision full --no-half --opt-sub-quad-attention;
    ' \
    `# comfyui` \
    -p 8188:8188 \
    -e ID_COMFYUI='comfyui' \
    -e REPO_COMFYUI='https://github.com/comfyanonymous/ComfyUI' \
    -e LAUNCH_COMFYUI='
        if [ ! -e "$ID_COMFYUI" ]; then
            git clone --depth 1 "$REPO_COMFYUI" "$ID_COMFYUI";
        fi;
        cd "$ID_COMFYUI";
        python3 -m venv "$VENV_DIR";
        pip install --pre torch torchvision torchaudio --index-url "$REPO_PYTORCH";
        pip install -r requirements.txt;
        python3 main.py --listen 0.0.0.0 --disable-auto-launch --dont-upcast-attention `#--force-fp16` `#--fp16-vae` `#--fp32-vae` `#--cpu-vae` `#--lowvram`;
    ' \
    \
    rocm-base \
    bash -c 'eval $LAUNCH_COMFYUI'
