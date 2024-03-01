FROM docker.io/rocm/dev-ubuntu-22.04:latest as deps

RUN <<-EOR
	apt-get update
	apt-get install -y nano git python3.10-venv libgoogle-perftools-dev
	apt-get clean
	rm -rf /var/lib/apt/lists/*
EOR

ENV LD_PRELOAD=libtcmalloc.so
ENV PIP_NO_CACHE_DIR=true

FROM deps as caddy

ARG CADDY_REPO="https://caddyserver.com/api/download?os=linux&arch=amd64"

RUN <<-EOR
	curl -o /opt/caddy  --location "$CADDY_REPO"
	chmod +x /opt/caddy
	ln -s /opt/caddy /usr/local/bin/
EOR

FROM caddy as zellij

ARG ZELLIJ_REPO="https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz"

RUN <<-EOR
	curl -L "$ZELLIJ_REPO" | tar -C /opt -xz
	ln -s /opt/zellij /usr/local/bin/
	cat <<-EOF >~/.zellijrc.kdl
		default_shell "bash"
		default_mode "locked"
		mirror_session true
		mouse_mode true
		layout {
			new_tab_template split_direction="horizontal" {
				pane focus=true stacked=true {
					children
				}
				pane size=1 borderless=true {
					plugin location="zellij:compact-bar"
				}
			}
			tab split_direction="horizontal" {
				pane focus=true stacked=true {
					children
				}
				pane size=8 borderless=true command="htop"
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
