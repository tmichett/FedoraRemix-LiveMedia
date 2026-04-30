---
title: Quickstart (container)
layout: default
nav_order: 4
parent: Home
---

# Quickstart — Container Build

Build a custom Fedora Remix live ISO using **Podman** and the **`fedora-livemedia-builder`** container image. The heavy work (lorax / livemedia-creator) runs inside the container; your host only needs Podman and enough disk space.

**Build Time:** Approximately 30–60 minutes
**Output:** A bootable Fedora Remix ISO under your configured output directory

---

## Prerequisites

### Required Software

Install the following on your **Fedora Linux** host:

```bash
sudo dnf install -y git podman python3-pyyaml
```

| Package | Purpose |
|:--------|:--------|
| **git** | Clone the repository. |
| **podman** | Container runtime that runs the builder image. |
| **python3-pyyaml** | Required by `Update_Remix_Config.sh` for safe YAML edits. |

If you are on a **SELinux-enforcing** host (Fedora default), also install:

```bash
sudo dnf install -y osbuild-selinux
```

### System Requirements

- **Disk Space:** At least 25 GB free (container image + build workspace + ISO output)
- **Memory:** 4 GB minimum, 8 GB recommended
- **CPU:** Multi-core recommended (build is CPU-intensive)
- **Internet:** Required for pulling the container image and downloading packages
- **Sudo:** Required — the build script uses `sudo podman` on Linux for loop-device access

### Optional Software

**VM testing** — if you plan to boot the ISO on the same machine:

```bash
sudo dnf install -y virt-manager libvirt qemu-kvm
sudo systemctl enable --now libvirtd
```

**Remote access** — if building over SSH:

```bash
sudo systemctl enable --now sshd
```

---

## Quick Start (5 Steps)

### Step 1: Clone the Repository

```bash
git clone https://github.com/tmichett/FedoraRemix-LiveMedia.git
cd FedoraRemix-LiveMedia
```

### Step 2: Configure with `Update_Remix_Config.sh`

Run the interactive configuration script. It writes to both `config.yml` (container properties) and `Setup/config.yml` (build settings) so they stay in sync:

```bash
./Update_Remix_Config.sh
```

**Prompts (in order)** — press Enter to keep the default shown in brackets:

| Prompt | What it sets | Notes |
|:-------|:-------------|:------|
| **SSH_Key_Location** | Path to your SSH key mounted into the container | e.g. `~/.ssh/github_id` |
| **Fedora_Remix_Location** | Host directory for ISO output, mounted as `/livemedia-creator` in the container | e.g. `/home/youruser/Remix_Builder` |
| **GitHub_Registry_Owner** | GHCR namespace for the builder image | Keep as **`tmichett`** if using the published image |
| **Fedora version** | Sets `Fedora_Version` and `fedora_version` in both configs | Must be between 30–99 |
| **PXE boot files** | Whether `Prepare_Web_Files.py` stages `vmlinuz`/`initrd.img` | Answer **no** unless you need network boot assets |

The script reminds you: if you pull from `ghcr.io/tmichett/fedora-livemedia-builder`, keep `GitHub_Registry_Owner` set to `tmichett`.

See [Configuration — Update_Remix_Config.sh]({{ site.baseurl }}{% link docs/configuration.md %}#update_remix_configsh) for the full field reference.

### Step 3: Verify Configuration (Recommended)

```bash
./Verify_Build_LiveMedia.sh
```

This checks:

- `Fedora_Version` (root `config.yml`) matches `fedora_version` (`Setup/config.yml`)
- The container image exists locally (and shows its creation date if found)
- `include_pxeboot_files` setting
- Offers to run `Build_LiveMedia.sh` when everything looks good

### Step 4: Build the ISO

If you answered **yes** at the verify prompt, the build starts automatically. Otherwise run it directly:

```bash
./Build_LiveMedia.sh
```

The script reads `config.yml`, pulls the container image if needed, and starts a privileged Podman container that:

1. Boots systemd and runs `entrypoint.sh` as a oneshot service.
2. Executes `Prepare_Web_Files.py` → `Prepare_LiveMedia_Build.py` → `LiveMedia_Enhanced_Build_Script.sh`.
3. Writes the finished ISO to `/livemedia-creator/result/images/` inside the container (your `Fedora_Remix_Location` on the host).

**Default mode (detached):** The container runs in the background and the script streams the build log (`/tmp/entrypoint.log`) in your current terminal. No second window needed.

**Build options:**

```bash
./Build_LiveMedia.sh -k FedoraRemixCosmic   # build a specific kickstart variant
./Build_LiveMedia.sh -l                       # list available kickstarts
./Build_LiveMedia.sh -a                       # attach interactively (old behavior)
```

### Step 5: Retrieve the ISO

When the build finishes, the script prints a success/failure line and notes that the container is still running for inspection.

**Find the ISO:**

```bash
ls -lh /home/youruser/Remix_Builder/result/images/*.iso
```

(Replace the path with your `Fedora_Remix_Location`.)

**Stop the container when done:**

```bash
sudo podman stop livemedia-builder
```

---

## Building the Container Image (Maintainers)

If you need to modify the container itself (add packages, change the entrypoint, etc.) rather than using the published image:

```bash
./build.sh    # builds from Containerfile, tags as ghcr.io/<owner>/fedora-livemedia-builder:<ver>
./push.sh     # pushes to GHCR (prompts for login)
```

See [Building the container]({{ site.baseurl }}{% link docs/building-container.md %}) for the full walkthrough.

---

## Customization

### Customizing Packages

Edit the package list before building:

```bash
vim Setup/Kickstarts/FedoraRemixPackages.ks
```

Add packages (one per line) or comment out unwanted ones with `#`.

### Customizing Kickstart Files

The kickstart files live under `Setup/Kickstarts/`:

```
Setup/Kickstarts/
├── FedoraRemix.ks              # Main kickstart (default, GNOME)
├── FedoraRemixCosmic.ks        # COSMIC desktop variant
├── FedoraRemixTiny.ks          # Minimal variant
├── FedoraRemixPackages.ks      # Shared package list
└── FedoraRemixRepos.ks         # Repository configuration
```

You can customize user accounts, network settings, firewall rules, SELinux policy, post-install scripts, and more via standard kickstart syntax.

### Building Different Variants

```bash
./Build_LiveMedia.sh -k FedoraRemixCosmic
./Build_LiveMedia.sh -k FedoraRemixTiny
```

Or omit `-k` to get the interactive kickstart menu.

---

## Troubleshooting

### Container Image Not Found

**Problem:** `Build_LiveMedia.sh` can't find the image locally.

**Solution:** Either let it pull automatically (takes 5–15 minutes), or build locally:

```bash
./build.sh
```

### Version Mismatch

**Problem:** `Verify_Build_LiveMedia.sh` reports mismatched Fedora versions.

**Solution:** Run `./Update_Remix_Config.sh` and enter the same version at the prompt.

### Loop Device / Permission Errors

**Problem:** The build fails with loop device or permission errors.

**Solution:** On Linux, `Build_LiveMedia.sh` automatically uses `sudo podman`. Ensure your user has sudo privileges.

### Build Fails or Container Exits Immediately

**Solution:**

```bash
sudo podman logs livemedia-builder       # check container logs
sudo podman exec -it livemedia-builder bash  # inspect inside the container
```

### Insufficient Disk Space

**Solution:** Ensure at least 25 GB free. Clean old builds:

```bash
rm -rf /home/youruser/Remix_Builder/result/images/*.iso
```

---

## See Also

- [Configuration]({{ site.baseurl }}{% link docs/configuration.md %}) — `config.yml`, `Setup/config.yml`, and `Update_Remix_Config.sh` reference
- [Building the container]({{ site.baseurl }}{% link docs/building-container.md %}) — how to build/push the container image
- [Quickstart (physical)]({{ site.baseurl }}{% link docs/quickstart-physical.md %}) — building directly on a Fedora host without containers
- [Build scripts]({{ site.baseurl }}{% link docs/build-scripts.md %}) — script reference
- [Troubleshooting]({{ site.baseurl }}{% link docs/troubleshooting.md %})
