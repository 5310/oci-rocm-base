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
	apt install -y bash curl tar nano git python3-venv libgoogle-perftools-dev
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
EOR

# # Install and setup Caddy

# ARG CADDY_REPO="https://caddyserver.com/api/download?os=linux&arch=amd64"

# RUN <<-EOR
# 	curl -o /opt/caddy --location "$CADDY_REPO"
# 	chmod +x /opt/caddy
# 	ln -s /opt/caddy /usr/local/bin/
# 	mkdir -p /etc/caddy/
# 	cat <<-EOF > /etc/caddy/Caddyfile
# 		respond "Hullo world!"
# 	EOF
# 	mkdir -p /etc/systemd/system/
# 	cat <<-EOF > /etc/systemd/system/caddy.service
# 		[Unit]
# 		Description=Caddy
# 		Documentation=https://caddyserver.com/docs/
# 		After=network.target network-online.target
# 		Requires=network-online.target

# 		[Service]
# 		Type=notify
# 		ExecStart=/usr/local/bin/caddy run --environ --config /etc/caddy/Caddyfile
# 		ExecReload=/usr/local/bin/caddy reload --config /etc/caddy/Caddyfile --force
# 		TimeoutStopSec=5s
# 		LimitNOFILE=1048576
# 		PrivateTmp=true
# 		ProtectSystem=full
# 		AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE

# 		[Install]
# 		WantedBy=multi-user.target
# 	EOF
# EOR

# EXPOSE 80
# EXPOSE 443

# Install and setup Zellij to launch with the shelll

ARG ZELLIJ_REPO="https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz"

RUN <<-EOR
	curl -L "$ZELLIJ_REPO" | tar -C /opt -xz
	ln -s /opt/zellij /usr/local/bin/
	cat <<-EOF > ~/.zellijrc.kdl
		default_shell "bash"
		mirror_session true
		mouse_mode true
		layout {
		    default_tab_template {
		        children;
		        pane size=10 borderless=true name="resource-monitor" {
		            command "btop"
		            args "--utf-force" "-p" "1"
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
