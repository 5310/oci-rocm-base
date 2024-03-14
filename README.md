# rocm-base

> A relatively stock image with just enough dependencies to setup PyTorch-based apps on AMD ROCm compatible hosts in comfort

---

Built from the [rocm/dev-ubuntu:22.04](https://hub.docker.com/r/rocm/dev-ubuntu-22.04) image. 

Built for and tested with rootless [Podman](https://podman.io/); versions 4.5.1 (Steam Deck 3.5) and 4.9.2 (EndeavourOS).

You might need to override the `HSA_OVERRIDE_GFX_VERSION` environment variable if you're on older or slightly obscure hardware.

---

To do a test run using the minimum required parameters, do:

```sh
podman container runlabel test ghcr.io/5310/rocm-base
```

To run a functional container with an exposed port and interactive shell, do:

```sh
podman container runlabel run ghcr.io/5310/rocm-base
```

To see what the required parameters are in order to write your own run command, print out a runlabel like so:

```sh
podman container runlabel --display run ghcr.io/5310/rocm-base
```

For a more elaborate example that can install and run Automatic1111's WebUI or ComfyUI from a persistent sibling directory, see [`run.sh`](run.sh)

---

Quit the container with `ctrl+q` from its console. 

Or, you know, kill it, because instability is the name of the game!