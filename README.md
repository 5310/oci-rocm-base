# rocm-base

A relatively \"stock\" image with just enough dependencies to setup PyTorch-based \"AI\" apps on AMD ROCm compatible hosts in comfort.

Built for and tested with rootless [Podman](https://podman.io/); version 4.5.1 (installed on the Steam Deck from SteamOS 3.5 onwards) and 4.9.2

---

To run using default parameters, run the runlabel `RUN` (and I am keeping that sentence in):

```sh
podman container runlabel run podman ghcr.io/5310/rocm-base
```

To check what those default parameters are to write your own run command, display the runlabel with:

```sh
podman container runlabel --display run podman ghcr.io/5310/rocm-base
```

Yes, it just assumes the GPU is a 66XX series, or the Steam Deck. Those are the defaults we wanted, so you'd _have_ to write your own run command, perhaps put it in a script, if you don't want that.

---

For a more elaborate example that can install and run Automatic1111's WebUI or ComfyUI from a persistent sibling directory, see [`run.sh`](run.sh)