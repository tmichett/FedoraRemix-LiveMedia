---
title: Quickstart (physical / VM)
layout: default
nav_order: 5
parent: Home
---

# Quickstart (physical / VM)

Use a **Fedora** host (bare metal or VM) with enough disk and RAM for a full live image build.

## Prepare the host

```bash
sudo dnf install -y git
git clone https://github.com/tmichett/FedoraRemix-LiveMedia.git
cd FedoraRemix-LiveMedia
sudo python3 Setup/Prepare_LiveMedia_Build.py
```

**`Prepare_LiveMedia_Build.py`** installs **lorax**, **anaconda** (required for **`livemedia-creator --no-virt`**), pykickstart, and related packages.

## Configure

1. Edit **`config.yml`** and **`Setup/config.yml`** (see [Configuration]({% link docs/configuration.md %})).
2. Run **`./Update_Remix_Config.sh`** if your workflow expects synced values.

## Build

```bash
sudo ./Build_LiveMedia_Physical.sh
```

Output lands under the configured **`build_directory`** (default **`/livemedia-creator`**). Inspect **`program.log`** on failure.

## See also

- [Build scripts]({% link docs/build-scripts.md %})
- [Troubleshooting]({% link docs/troubleshooting.md %})
