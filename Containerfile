FROM docker.io/rocm/dev-ubuntu-22.04:latest as deps

RUN <<-END
	apt-get update
	apt-get install -y nano git python3.10-venv libgoogle-perftools-dev
	apt-get clean
	rm -rf /var/lib/apt/lists/*
END

ENV LD_PRELOAD=libtcmalloc.so
ENV PIP_NO_CACHE_DIR=true

FROM deps as caddy

ARG CADDY_REPO="https://caddyserver.com/api/download?os=linux&arch=amd64"

RUN <<-END
	curl -o /opt/caddy  --location "$CADDY_REPO"
	chmod +x /opt/caddy
	ln -s /opt/caddy /usr/local/bin/
END

FROM caddy as zellij

ARG ZELLIJ_REPO="https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz"

RUN <<-END
	curl -L "$ZELLIJ_REPO" | tar -C /opt -xz
	ln -s /opt/zellij /usr/local/bin/
	cat <<-EOF >~/.zellijrc 
		default_shell "bash"
		default_layout "compact"
		mouse_mode true
		mirror_session true
	EOF
	cat <<-EOF >>~/.bashrc 
		if [[ -z "\$ZELLIJ" ]]; then
			zellij --config ~/.zellijrc attach -c console
			exit
		fi
	EOF
END
