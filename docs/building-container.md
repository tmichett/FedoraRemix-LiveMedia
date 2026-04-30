---
title: Building the container
layout: default
nav_order: 6
parent: Home
---

# Building the container image

The Fedora Remix LiveMedia builder runs inside a Podman container based on the stock `fedora:<version>` image. This guide covers building, pushing, and using the container image.

## Prerequisites

- **Podman** installed (`dnf install podman` on Fedora).
- A configured `config.yml` at the repo root. Run `./Update_Remix_Config.sh` first if this is a fresh clone (see [Configuration]({{ site.baseurl }}{% link docs/configuration.md %})).

## 1. Configure the build

`config.yml` controls the image name and Fedora base version. The image tag is derived automatically:

```
ghcr.io/<GitHub_Registry_Owner>/fedora-livemedia-builder:<Fedora_Version>
```

To change the Fedora version or registry owner, run:

```bash
./Update_Remix_Config.sh
```

This sets `Fedora_Version`, `GitHub_Registry_Owner`, `SSH_Key_Location`, and `Fedora_Remix_Location` in `config.yml` and keeps `Setup/config.yml` in sync. See [Update_Remix_Config.sh]({{ site.baseurl }}{% link docs/configuration.md %}#update_remix_configsh) for details.

## 2. Build the image

From the repo root:

```bash
./build.sh
```

This runs `podman build` with the `Containerfile`, passing `FEDORA_VERSION` as a build arg. The resulting image is tagged with the full GHCR path (e.g. `ghcr.io/tmichett/fedora-livemedia-builder:44`).

### What the Containerfile installs

The image includes everything needed for `livemedia-creator` (lorax) ISO builds:

- **lorax / livemedia-creator** — the ISO build toolchain
- **anaconda** — required for `--no-virt` mode
- **pykickstart** — `ksflatten` for kickstart processing
- **httpd / rsync** — used by `Prepare_Web_Files.py`
- **sshfs / git** — source checkout and SSH key mounts
- **osbuild-selinux** — SELinux policy modules loaded by the entrypoint
- **systemd** — the container boots with `init`, running the build as a systemd service

## 3. Push to the registry

After a successful build, push the image to GitHub Container Registry:

```bash
./push.sh
```

You will be prompted to log in to `ghcr.io` if not already authenticated. The script verifies the local image exists before pushing.

To authenticate beforehand:

```bash
podman login ghcr.io
```

## 4. Run a build with the container

Once the image is available (locally or on the registry), use `Build_LiveMedia.sh` to launch a build:

```bash
./Build_LiveMedia.sh
```

The script reads `config.yml`, pulls the image, and starts a privileged Podman container that:

1. Mounts your SSH key, the repo workspace, and the output directory.
2. Boots systemd and runs `entrypoint.sh` as a oneshot service.
3. Executes `Prepare_Web_Files.py` → `Prepare_LiveMedia_Build.py` → `LiveMedia_Enhanced_Build_Script.sh`.
4. Writes the finished ISO to `/livemedia-creator/result/` (your `Fedora_Remix_Location` on the host).

### Options

```bash
./Build_LiveMedia.sh -k FedoraRemixCosmic   # specific kickstart
./Build_LiveMedia.sh -l                       # list available kickstarts
./Build_LiveMedia.sh -a                       # attach interactively
```

By default the container runs detached and the script streams the build log in your terminal.

## 5. Using a pre-built image

If you don't need to modify the container, skip steps 2–3 and use the published image directly. As long as `GitHub_Registry_Owner` in `config.yml` is set to `tmichett` (the default), `Build_LiveMedia.sh` will pull the published image from `ghcr.io/tmichett/fedora-livemedia-builder:<version>`.

## Troubleshooting

| Problem | Fix |
|:--------|:----|
| `build.sh` fails with missing `config.yml` | Run from the repo root, or run `./Update_Remix_Config.sh` to generate it. |
| `push.sh` says local image not found | Run `./build.sh` first. |
| `Build_LiveMedia.sh` fails with permission errors | On Linux, the script automatically uses `sudo podman` for loop-device access. Make sure your user has `sudo` privileges. |
| Container exits immediately | Check `podman logs livemedia-builder` or attach with `-a` flag for interactive troubleshooting. |

See also [Quickstart (container)]({{ site.baseurl }}{% link docs/quickstart-container.md %}) and [Troubleshooting]({{ site.baseurl }}{% link docs/troubleshooting.md %}).
