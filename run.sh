#!/bin/bash

CONTAINER='rocm-base'

VOLUME=${1:-'./volume'}
APP=${2:-'comfyui'}

[ -z "$1" ] && read -er -p "Mount volume: " -i "$VOLUME" VOLUME || echo "Mounting $VOLUME..."
[ -z "$2" ] && read -er -p "Launch app: " -i "$APP" APP || echo "Launching $APP..."

# Pull or re/build image

podman pull ghcr.io/5310/rocm-base && podman tag ghcr.io/5310/rocm-base:latest $CONTAINER:latest || podman build --no-cache --tag $CONTAINER .

# Run container

echo Running the container...
mkdir -p "$VOLUME"
podman run -ditq --rm \
	--name $CONTAINER \
	--hostname $CONTAINER \
	\
	--group-add video \
	--group-add render \
	--device /dev/kfd:/dev/kfd \
	--device /dev/dri:/dev/dri \
	\
	-e PORT=80 \
	-p 8080:80 \
	-v "$VOLUME":/root/volume:U,z \
	-w "/root/volume" \
	\
	-e VENV_DIR='/root/volume/environment/venv' \
	-e PYTORCH_REPO='https://download.pytorch.org/whl/rocm6.2' \
	-e PYTORCH_HIP_ALLOC_CONF='garbage_collection_threshold:0.9,max_split_size_mb:256' \
	-e HSA_OVERRIDE_GFX_VERSION='10.3.0' \
	\
	$CONTAINER \
	bash -c '
		mkdir -p /root/volume/app
		mkdir -p /root/volume/environment
		bash
	'
sleep 3;

# Launch app

echo Launching app...
case $APP in

	# ComfyUI
	'comfyui')
	echo test
		podman exec -i $CONTAINER zellij run -n "$APP" --cwd '/root/volume/app' -- bash -c '
			echo "Starting $APP..."
			COMFYUI_NAME="comfyui"
			COMFYUI_REPO="https://github.com/comfyanonymous/ComfyUI"
			COMFYUI_MANAGER_REPO="https://github.com/ltdrdata/ComfyUI-Manager"
			COMFYUI_ARGS="--listen 0.0.0.0 --port $PORT --disable-auto-launch"
			if [ ! -e "$COMFYUI_NAME" ]; then
				git clone --depth 1 "$COMFYUI_REPO" "$COMFYUI_NAME"
			fi
			cd "$COMFYUI_NAME"
			if [ ! -e "custom_nodes/ComfyUI-Manager" ]; then
				git clone --depth 1 "$COMFYUI_MANAGER_REPO" "custom_nodes/ComfyUI-Manager"
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

echo Attaching to the container
podman attach $CONTAINER
clear
