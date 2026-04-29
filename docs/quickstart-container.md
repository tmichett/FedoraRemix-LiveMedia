---
title: Quickstart (container)
layout: default
nav_order: 4
parent: Home
---

# Quickstart (container)

Recommended path: **Podman** + **`fedora-livemedia-builder`** image from **`ghcr.io`**.

## Prerequisites

- **Podman** (or Docker with equivalent volume flags).
- **`config.yml`** at repo root with **`fedora_version`** and **`build_name`** set.
- **`Setup/config.yml`** with **`kickstart_file`** and matching **`fedora_version`**.
- Host directory for output (default **`/livemedia-creator`**) owned by your user.

## Verify and build

```bash
./Verify_Build_LiveMedia.sh
```

Answer prompts for Fedora version alignment and optional **`exec ./Build_LiveMedia.sh`**.

## Manual build

```bash
./Build_LiveMedia.sh
```

The script pulls **`ghcr.io/tmichett/fedora-livemedia-builder:<fedora_version>`**, mounts the repository and **`/livemedia-creator`**, and runs **`LiveMedia_Enhanced_Build_Script.sh`** inside the container entrypoint.

## Image build (maintainers)

From the repo root:

```bash
./build.sh    # build local image
./push.sh     # push to registry (requires auth)
```

See **`README.md`** for **`Containerfile`**, **`entrypoint.sh`**, and service units.

## See also

- [Quickstart (physical)]({% link docs/quickstart-physical.md %})
- [Troubleshooting]({% link docs/troubleshooting.md %})
