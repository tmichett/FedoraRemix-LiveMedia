---
title: Configuration
layout: default
nav_order: 3
parent: Home
---

# Configuration

## Root `config.yml`

Used by **`Verify_Build_LiveMedia.sh`**, **`Build_LiveMedia.sh`**, and related scripts. Typical fields:

| Field | Purpose |
|:------|:--------|
| **`fedora_version`** | Fedora release used for container tag and tooling (e.g. **`43`**). |
| **`build_name`** | Logical name for the remix; used in final ISO filename. |
| **`build_directory`** | Host path mounted as **`/livemedia-creator`** in the container (default **`/livemedia-creator`**). |

Run **`./Update_Remix_Config.sh`** after editing **`config.yml`** so dependent files stay aligned.

## `Setup/config.yml`

Used by **`Prepare_LiveMedia_Build.py`** and **`LiveMedia_Enhanced_Build_Script.sh`**. Defines:

- **`fedora_version`** — should match **`config.yml`** for consistent trees (verifier can enforce this).
- **`kickstart_file`** — path under **`Setup/Kickstarts/`** (e.g. **`FedoraRemix.ks`**).
- **`build_directory`** — same semantics as root config for native builds.

## Verifier

**`Verify_Build_LiveMedia.sh`** optionally checks that **`fedora_version`** matches in both YAML files, verifies the **`ghcr.io`** image exists for that version, and can launch **`Build_LiveMedia.sh`**.

See also [Build scripts]({% link docs/build-scripts.md %}).
