---
title: Troubleshooting
layout: default
nav_order: 7
parent: Home
---

# Troubleshooting

## `Module 'network-legacy' cannot be found` (dracut)

Modern dracut renamed or removed **`network-legacy`**. Kickstarts and dracut snippets under **`Setup/Kickstarts`** should use **`network`** instead of **`network-legacy`** in **`add_dracut_modules`** / **`omit_dracut_modules`**. Check **`program.log`** for the exact module line.

## `no-virt requires anaconda`

**`livemedia-creator --no-virt`** needs **anaconda** installed in the build environment. The container **`Containerfile`** and **`Prepare_LiveMedia_Build.py`** include **anaconda** for this reason.

## Permission denied on `/tmp/remix_kickstart.txt`

When the kickstart is bind-mounted **read-only** (`:ro`), the entrypoint must not overwrite it. **`entrypoint.sh`** detects a read-only mount and skips writing that file.

## Where is my ISO?

During the build, look for **`images/boot.iso`**. After finalize, **`images/<BUILD_NAME>-f<VER>-<arch>.iso`**. **`LiveMedia_Enhanced_Build_Script.sh`** logs moves and **`.treeinfo`** updates.

## Deep diagnosis

- **`program.log`** — primary anaconda / lorax narrative.
- **`livemedia-creator.log`** — wrapper and invocation details.
- **`lorax-packages.log`** — package set issues.

If a step fails repeatedly, capture the last 200 lines of **`program.log`** and open an issue with **`fedora_version`** and kickstart name.
