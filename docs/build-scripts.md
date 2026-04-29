---
title: Build scripts
layout: default
nav_order: 6
parent: Home
---

# Build scripts

## `Verify_Build_LiveMedia.sh`

Pre-flight checks before a container build:

- Reads **`config.yml`** and **`Setup/config.yml`**.
- Optionally requires the same **`fedora_version`** in both files.
- Confirms **`ghcr.io/tmichett/fedora-livemedia-builder:<ver>`** exists (optional **`skopeo`**).
- Can **`exec ./Build_LiveMedia.sh`** when you confirm.

## `LiveMedia_Enhanced_Build_Script.sh`

Main orchestration inside the container or on a prepared host:

- Resolves kickstart path and **`fedora_version`**.
- Runs **`livemedia-creator`** with the configured kickstart.
- **`resolve_build_iso`** prefers **`images/boot.iso`** (and top-level **`*.iso`** as fallback).
- **`finalize_named_iso`** renames **`images/boot.iso`** to **`images/<BUILD_NAME>-f<VER>-<arch>.iso`**, updates **`.treeinfo`**, and avoids duplicating a full second ISO copy on disk.

## `Prepare_LiveMedia_Build.py`

Host preparation: package installs, directories, and parity with container dependencies (**anaconda**, lorax, etc.).

## `Update_Remix_Config.sh`

Propagates changes from **`config.yml`** into generated or dependent paths where applicable.

## Container entrypoint

**`entrypoint.sh`**: **`Prepare_Web`** → **`Prepare_LiveMedia`** → **`LiveMedia_Enhanced_Build_Script.sh`**; writes status files; skips writing **`/tmp/remix_kickstart.txt`** when that path is bind-mounted read-only.
