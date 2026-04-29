---
title: Overview
layout: default
nav_order: 2
parent: Home
---

# Overview

Fedora Remix LiveMedia produces a **bootable live ISO** using **`livemedia-creator`** from **lorax**, not **`livecd-creator`**. Kickstarts and shared assets live under **`Setup/Kickstarts`** and align with [Fedora Remix](https://github.com/tmichett/Fedora_Remix).

## What gets built

- **Output directory**: **`/livemedia-creator`** (default; configurable in **`config.yml`**).
- **Primary artifact**: **`images/boot.iso`** during the build; after finalize, **`images/<BUILD_NAME>-f<VER>-<arch>.iso`** (see **`LiveMedia_Enhanced_Build_Script.sh`**).
- **Logs**: **`program.log`**, **`livemedia-creator.log`**, **`lorax-packages.log`** under the build tree.

## Host vs container

| Path | Use case |
|:-----|:---------|
| **`Build_LiveMedia.sh`** | Podman: image **`ghcr.io/.../fedora-livemedia-builder:<ver>`**, mounts kickstarts and **`/livemedia-creator`**. |
| **`Build_LiveMedia_Physical.sh`** | Bare metal or VM on Fedora with **`dnf install lorax`** (and dependencies from **`Prepare_LiveMedia_Build.py`**). |

## Key differences from livecd-creator

- Uses **lorax** pipeline and **anaconda** for **`--no-virt`** installs.
- Dracut modules follow current Fedora (**`network`** instead of deprecated **`network-legacy`** in initrd snippets).
- ISO layout and tooling differ; do not assume livecd-creator paths inside the ISO.

## Next steps

- [Quickstart (container)]({% link docs/quickstart-container.md %})
- [Configuration]({% link docs/configuration.md %})
