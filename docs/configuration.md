---
title: Configuration
layout: default
nav_order: 3
parent: Home
---

# Configuration

## Root `config.yml`

The root `config.yml` drives all container operations — **`Build_LiveMedia.sh`**, **`build.sh`**, **`push.sh`**, and **`Verify_Build_LiveMedia.sh`** all read from it. The file has a single `Container_Properties` block:

| Field | Purpose |
|:------|:--------|
| **`Fedora_Version`** | Fedora release number (e.g. **`44`**). Sets the base image tag and is passed as a build arg to the Containerfile. |
| **`SSH_Key_Location`** | Path to an SSH private key on the host (e.g. **`~/.ssh/github_id`**). Mounted read-only at **`/root/github_id`** in the container for Git/SSH operations. |
| **`Fedora_Remix_Location`** | Host directory mounted at **`/livemedia-creator`** in the container. The finished ISO and build logs are written here. |
| **`GitHub_Registry_Owner`** | GHCR namespace for the builder image (e.g. **`tmichett`**). The full image name becomes **`ghcr.io/<owner>/fedora-livemedia-builder:<version>`**. |

Example:

```yaml
Container_Properties:
  Fedora_Version: "44"
  SSH_Key_Location: "~/.ssh/github_id"
  Fedora_Remix_Location: "/home/travis/Remix_Builder"
  GitHub_Registry_Owner: "tmichett"
```

## `Setup/config.yml`

Used by **`Prepare_LiveMedia_Build.py`** and **`LiveMedia_Enhanced_Build_Script.sh`** inside the container. Key fields:

- **`fedora_version`** — must match the root `config.yml` value for consistent package trees.
- **`include_pxeboot_files`** — whether to include PXE boot files in the web-assets step (`true`/`false`).

## `Update_Remix_Config.sh`

**`Update_Remix_Config.sh`** is an interactive script that keeps both configuration files in sync. Run it whenever you need to change the Fedora version, container registry settings, or build paths — it writes to both `config.yml` and `Setup/config.yml` in a single pass so they never drift out of sync.

### What it configures

| Prompt | Config file | YAML key | Description |
|:-------|:------------|:---------|:------------|
| SSH key path | `config.yml` | `SSH_Key_Location` | Host path to the SSH private key mounted into the container. |
| Remix directory | `config.yml` | `Fedora_Remix_Location` | Host directory bind-mounted as `/livemedia-creator`. |
| Registry owner | `config.yml` | `GitHub_Registry_Owner` | GHCR namespace — determines which container image is pulled/pushed. Leave as **`tmichett`** to use the published images. |
| Fedora version | Both | `Fedora_Version` / `fedora_version` | Updated in both files simultaneously. |
| PXE boot files | `Setup/config.yml` | `include_pxeboot_files` | Whether `Prepare_Web_Files.py` includes PXE boot artifacts. |

### Usage

```bash
./Update_Remix_Config.sh
```

The script reads the current values from both config files and displays them as defaults in brackets. Press **Enter** to keep a value, or type a new one. Fedora version is validated to be a number between 30 and 99.

```bash
./Update_Remix_Config.sh --help    # show usage summary
```

### When to run it

- **First clone** — set your SSH key path, output directory, and registry owner.
- **New Fedora release** — bump the version once and both configs update.
- **Switching registries** — change the owner so `Build_LiveMedia.sh` and `build.sh` pull/push the right image.

## Verifier

**`Verify_Build_LiveMedia.sh`** optionally checks that **`fedora_version`** matches in both YAML files, verifies the **`ghcr.io`** image exists for that version, and can launch **`Build_LiveMedia.sh`**.

See also [Build scripts]({% link docs/build-scripts.md %}).
