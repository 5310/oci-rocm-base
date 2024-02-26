FROM docker.io/rocm/dev-ubuntu-22.04:latest

RUN apt-get update &&\
    apt-get install -y nano wget git python3.10-venv libgoogle-perftools-dev &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/*

ENV LD_PRELOAD=libtcmalloc.so
ENV PIP_NO_CACHE_DIR=true
