FROM docker.io/greyltc/archlinux-aur:latest AS rocm-base-arch

LABEL org.opencontainers.image.title=rocm-base-arch
LABEL org.opencontainers.image.description='A relatively stock Arch image with just enough dependencies to setup PyTorch-based apps on AMD ROCm compatible hosts in comfort. (See the runlabels for required permissions.)'
LABEL org.opencontainers.image.base.name="docker.io/greyltc/archlinux-aur"
LABEL org.opencontainers.image.url="https://github.com/5310/oci-rocm-base-arch"
LABEL io.artifacthub.package.readme-url=https://raw.githubusercontent.com/5310/rocm-base/arch/README.md

LABEL TEST='\
	podman run -itq --rm \
		--group-add video \
		--group-add render \
		--device /dev/kfd:/dev/kfd \
		--device /dev/dri:/dev/dri \
		${IMAGE} \
		bash -c "rocminfo"\
'
LABEL RUN='\
	podman run -itq --rm \
		--group-add video \
		--group-add render \
		--device /dev/kfd:/dev/kfd \
		--device /dev/dri:/dev/dri \
		\
		-e PORT=80 \
		-p 8888:80 \
		\
		-v .:/root/volume:U,z \
		-w /root/volume \
		\
		\${IMAGE} \
		bash \
'

RUN pacman -Syu --noconfirm &&\
	pacman -S --noconfirm bash curl tar nano git gperftools &&\
	pacman -S --noconfirm rocm-core rocminfo rocm-smi-lib &&\
	#aur-install ollama-rocm-git &&\
	pacman -Sc --noconfirm &&\
	ln -s /opt/rocm/bin/* /usr/local/bin &&\
	echo Done

ENV PIP_NO_CACHE_DIR="true"
ENV VENV_DIR=${VENV_DIR:-"/root/volume/environment/venv"}
ENV PYTORCH_REPO=${PYTORCH_REPO:-"https://download.pytorch.org/whl/nightly/rocm6.0"}
