# rocm-base-arch

> A relatively stock Arch image with just enough dependencies to setup PyTorch-based apps on AMD ROCm compatible hosts in comfort

---

Built from the [greyltc/archlinux-aur](https://hub.docker.com/r/greyltc/archlinux-aur) image. 

Built for and tested with rootless [Podman](https://podman.io/); versions 4.5.1 (Steam Deck 3.5) and 4.9.2 (EndeavourOS).

You might need to override the `HSA_OVERRIDE_GFX_VERSION` environment variable if you're on older or slightly obscure hardware.

---

To do a test run using the minimum required parameters, do:

```sh
podman container runlabel test ghcr.io/5310/rocm-base-arch
```

To run a functional container with an exposed port and interactive shell, do:

```sh
podman container runlabel run ghcr.io/5310/rocm-base-arch
```

To see what the required parameters are in order to write your own run command, print out a runlabel like so:

```sh
podman container runlabel --display run ghcr.io/5310/rocm-base-arch
```