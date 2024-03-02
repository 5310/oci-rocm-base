FROM docker.io/rocm/dev-ubuntu-22.04:latest

RUN <<-EOR
	apt-get update
	apt-get install -y bash curl tar nano git python3.10-venv libgoogle-perftools-dev
	apt-get clean
	rm -rf /var/lib/apt/lists/*
EOR

ENV LD_PRELOAD=libtcmalloc.so
ENV PIP_NO_CACHE_DIR=true

# ARG CADDY_REPO="https://caddyserver.com/api/download?os=linux&arch=amd64"

# RUN <<-EOR
# 	curl -o /opt/caddy --location "$CADDY_REPO"
# 	chmod +x /opt/caddy
# 	ln -s /opt/caddy /usr/local/bin/
# 	mkdir -p /etc/caddy/
# 	<<-EOF > /etc/caddy/Caddyfile
# 		respond "Hullo world!"
# 	EOF
# 	mkdir -p /etc/systemd/system/
# 	<<-EOF > /etc/systemd/system/caddy.service
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

ARG ZELLIJ_REPO="https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz"

RUN <<-EOR
	curl -L "$ZELLIJ_REPO" | tar -C /opt -xz
	ln -s /opt/zellij /usr/local/bin/
	cat <<-EOF >~/.zellijrc.kdl
		default_shell "bash"
		mirror_session true
		mouse_mode true
		layout {
			new_tab_template split_direction="horizontal" {
				pane focus=true {
					children
				}
				pane size=1 borderless=true {
					plugin location="zellij:compact-bar"
				}
			}
			tab split_direction="horizontal" {
				pane focus=true {
					children
				}
				pane size=10 borderless=true name="rocm-smi" command="/opt/rocm/bin/rocm-smi"
				pane size=1 borderless=true {
					plugin location="zellij:compact-bar"
				}
			}
		}
	EOF
	cat <<-EOF >>~/.bashrc 
		if [[ -z "\$ZELLIJ" ]]; then
			zellij --layout ~/.zellijrc.kdl attach -c console
			exit
		fi
	EOF
EOR
