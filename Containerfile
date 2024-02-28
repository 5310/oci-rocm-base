FROM docker.io/rocm/dev-ubuntu-22.04:latest

RUN apt-get update &&\
    apt-get install -y nano git python3.10-venv libgoogle-perftools-dev &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/*

# RUN curl --location "https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz" |\ 
#     tar -C "/opt" -xz &&\
#     ln -s /opt/zellij /usr/local/bin/ &&\
#     echo 'eval "$(zellij setup --generate-auto-start bash)"' >> ~/.bashrc

ENV LD_PRELOAD=libtcmalloc.so
ENV PIP_NO_CACHE_DIR=true
