#!/bin/bash

CONTAINER='rocm-base'

VOLUME=${1:-'./volume'}
APP=${2:-'sdwebui'}

[ -z "$1" ] && read -er -p "Mount volume: " -i "$VOLUME" VOLUME || echo "Mounting $VOLUME..."
[ -z "$2" ] && read -er -p "Launch app: " -i "$APP" APP || echo "Launching $APP..."

# Re/build image

podman build --no-cache --tag $CONTAINER - < Containerfile

# Run container

mkdir -p "$VOLUME"
podman run -ditq --rm \
	--name $CONTAINER \
	--hostname $CONTAINER \
	--group-add video \
	--group-add render \
	--device /dev/kfd:/dev/kfd \
	--device /dev/dri:/dev/dri \
	-e PORT=80 \
	-p 8080:80 \
	-v "$VOLUME":/root/volume:U,z \
	-w "/root/volume" \
	\
	-e VENV_DIR='/root/volume/environment/venv' \
	-e PYTORCH_REPO='https://download.pytorch.org/whl/nightly/rocm6.0' \
	-e PYTORCH_HIP_ALLOC_CONF='garbage_collection_threshold:0.9,max_split_size_mb:256' \
	-e HSA_OVERRIDE_GFX_VERSION='10.3.0' \
	\
	$CONTAINER \

podman exec -i $CONTAINER bash -c '
	mkdir -p /root/volume/app
	mkdir -p /root/volume/environment
'

# Launch app

case $APP in

	# Automatic1111's Stable Diffusion WebUI
 	'sdwebui') 
		podman exec -i $CONTAINER zellij run -n "$APP" --cwd '/root/volume/app' -- bash -c '
			echo "Starting $APP..."
			SDWEBUI_NAME="sdwebui"
			SDWEBUI_REPO="https://raw.githubusercontent.com/AUTOMATIC1111/stable-diffusion-webui/master/webui.sh"
			SDWEBUI_ARGS="-f --listen --port $PORT --enable-insecure-extension-access --data-dir /root/volume/library --no-download-sd-model  --precision full --no-half --opt-sub-quad-attention"
			curl -sSL -f "$SDWEBUI_REPO" | \
				clone_dir="$SDWEBUI_NAME" \
				venv_dir="$VENV_DIR" \
				TORCH_COMMAND="pip install --pre torch torchvision torchaudio --index-url \"$PYTORCH_REPO\"" \
				bash -s - $SDWEBUI_ARGS;
		'
		;;

	# ComfyUI
	'comfyui')
		podman exec -i $CONTAINER zellij run -n "$APP" --cwd '/root/volume/app' -- bash -c '
			echo "Starting $APP..."
			COMFYUI_NAME="comfyui"
			COMFYUI_REPO="https://github.com/comfyanonymous/ComfyUI"
			COMFYUI_MANAGER_REPO="https://github.com/ltdrdata/ComfyUI-Manager"
			COMFYUI_ARGS="--listen 0.0.0.0 --port $PORT --disable-auto-launch --dont-upcast-attention"
			if [ ! -e "$COMFYUI_NAME" ]; then
				git clone --depth 1 "$COMFYUI_REPO" "$COMFYUI_NAME"
			fi
			cd "$COMFYUI_NAME"
			<<-EOF > extra_model_paths.yaml
				a111:
					base_path: root/volume/
					checkpoints: models/Stable-diffusion
					configs: models/Stable-diffusion
					vae: models/VAE
					loras: |
						models/Lora
						models/LyCORIS
					upscale_models: |
						models/ESRGAN
						models/RealESRGAN
						models/SwinIR
					embeddings: embeddings
					hypernetworks: models/hypernetworks
					controlnet: models/ControlNet
			EOF
			git clone --depth 1 "$COMFYUI_REPO" "$COMFYUI_NAME"
			if [ ! -e "custom_nodes/ComfyUI-Manager" ]; then
				git clone --depth 1 "$COMFYUI_MANAGER_REPO" custom_nodes/ComfyUI-Manager
			fi
			python3 -m venv "$VENV_DIR"
			source "$VENV_DIR/bin/activate"
			pip install --pre torch torchvision torchaudio --index-url "$PYTORCH_REPO"
			pip install -r requirements.txt
			python3 main.py $COMFYUI_ARGS
		'
		;;

	*)
		echo "Unknown app: $APP"
		podman kill $CONTAINER
		exit 1
		;;

esac

# Attach terminal

podman attach $CONTAINER