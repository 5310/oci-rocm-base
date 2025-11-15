FROM docker.io/rocm/dev-ubuntu-24.04:latest

LABEL org.opencontainers.image.description='A relatively stock image with just enough dependencies to setup PyTorch-based apps on AMD ROCm compatible hosts in comfort'
LABEL org.opencontainers.image.base.name="docker.io/rocm/dev-ubuntu-24.04:latest"
LABEL org.opencontainers.image.url="https://github.com/5310/oci-rocm-base"

# Runlabels

LABEL TEST='\
	podman run -itq --replace --rm \
		--group-add video \
		--group-add render \
		--device /dev/kfd:/dev/kfd \
		--device /dev/dri:/dev/dri \
		${IMAGE} \
		bash -c "rocminfo"\
'
LABEL RUN='\
	podman run -itq --replace --rm \
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

# Install the essential dependencies

RUN <<-EOR
	apt update
	apt install -y bash curl tar nano git software-properties-common python3-venv libgoogle-perftools-dev 
	apt clean
	rm -rf /var/lib/apt/lists/*
EOR

ENV LD_PRELOAD="libtcmalloc.so"
ENV PIP_NO_CACHE_DIR="true"
ENV VENV_DIR=${VENV_DIR:-"/root/volume/environment/venv"}
ENV PYTORCH_REPO=${PYTORCH_REPO:-"https://download.pytorch.org/whl/rocm6.2"}

# Install BTOP++

ARG BTOP_REPO="https://github.com/aristocratos/btop"

RUN <<-EOR
	add-apt-repository ppa:ubuntu-toolchain-r/test -y
	apt install -y g++-15
	update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-15 150 --slave /usr/bin/g++ g++ /usr/bin/g++-15 --slave /usr/bin/gcov gcov /usr/bin/gcov-15
	cd /tmp
	git clone --depth 1 "$BTOP_REPO"
	cd btop
	make
	chmod +x bin/btop
	mv bin/btop /usr/local/bin
	cd /
	rm -Rf /tmp/btop
	mkdir -p ~/.config/btop/
	cat <<-EOF > ~/.config/btop/btop.conf
		theme_background = False
		presets = "cpu:0:block cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default"
	EOF
	cat ~/.config/btop/btop.conf
	apt remove -y g++-15
	apt clean
	rm -rf /var/lib/apt/lists/*
EOR

ARG ZELLIJ_REPO="https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz"

RUN <<-EOR
	curl -L "$ZELLIJ_REPO" | tar -C /opt -xz
	ln -s /opt/zellij /usr/local/bin/
	cat <<-EOF > ~/.zellijrc.kdl
		default_shell "bash"
		mirror_session true
		mouse_mode true
		env {
		    LANG "en_US.UTF-8"
		}
		layout {
		    default_tab_template {
		        children;
		        pane size=10 borderless=true name="resource-monitor" {
		            command "btop"
		            args "-p" "1"
		        }
		        pane size=2 borderless=true {
		            plugin location="zellij:status-bar"
		        }
		    }
		    swap_tiled_layout name="base" {
		        tab max_panes=5 {
		            pane {
		            	children;
		            }
		        }
		    }
		    swap_tiled_layout name="stacked" {
			    tab {
			        pane split_direction="horizontal" stacked=true {
			            children;
			        }
			    }
			}
		}
	EOF
	cat <<-EOF >> ~/.bashrc 
		quit () {
		    if [[ "\$ZELLIJ" ]]; then
		        pkill zellij
		    fi
		}
		if [[ -z "\$ZELLIJ" ]]; then
		    zellij --layout ~/.zellijrc.kdl attach -c console
		    exit
		fi
	EOF
EOR
