---
title: Home
layout: default
nav_order: 1
has_children: true
---

# Fedora Remix LiveMedia
{: .fs-9 }

Bootable **live ISOs** with **`livemedia-creator`** (lorax), using the same **`Setup/Kickstarts`** and assets as [Fedora Remix](https://github.com/tmichett/Fedora_Remix).
{: .fs-6 .fw-300 }

---

## Quickstart

| Guide | Description |
|:------|:------------|
| [Container build (recommended)]({{ site.baseurl }}{% link docs/quickstart-container.md %}) | Podman image **`fedora-livemedia-builder`**, **`Build_LiveMedia.sh`**, reproducible environment |
| [Physical / VM build]({{ site.baseurl }}{% link docs/quickstart-physical.md %}) | Native Fedora host: **`Build_LiveMedia_Physical.sh`** and `/livemedia-creator` |

---

## Documentation

| Topic | Description |
|:------|:------------|
| [Overview]({{ site.baseurl }}{% link docs/overview.md %}) | Paths, outputs, and how LiveMedia differs from livecd-creator |
| [Configuration]({{ site.baseurl }}{% link docs/configuration.md %}) | **`config.yml`**, **`Setup/config.yml`**, **`Update_Remix_Config.sh`** |
| [Build scripts]({{ site.baseurl }}{% link docs/build-scripts.md %}) | **`Verify_Build_LiveMedia.sh`**, **`LiveMedia_Enhanced_Build_Script.sh`**, prepare scripts |
| [Troubleshooting]({{ site.baseurl }}{% link docs/troubleshooting.md %}) | dracut, **`program.log`**, anaconda lock, ISO location |
| [GitHub Pages]({{ site.baseurl }}{% link docs/github-pages.md %}) | Enable Pages and how this site is published |

---

## Related projects

| Project | Role |
|:--------|:-----|
| [Fedora Remix](https://github.com/tmichett/Fedora_Remix) | Source kickstarts, themes, and livecd-creator workflow |
| [RemixBuilder](https://github.com/tmichett/RemixBuilder) | Container pattern this repo mirrors for **livemedia-creator** |
