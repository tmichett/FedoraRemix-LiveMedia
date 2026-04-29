---
title: Quickstart (physical / VM)
layout: default
nav_order: 5
parent: Home
---

# Quickstart — Physical / VM Build

Build a custom Fedora Remix live ISO directly on a **Fedora Linux** machine (physical or VM) using **livemedia-creator** from **lorax**. This method installs the build toolchain on your host — no containers required.

**Build Time:** Approximately 30–60 minutes
**Output:** A bootable Fedora Remix ISO under `/livemedia-creator/result/images/`

> Looking for the containerized method? See [Quickstart (container)]({% link docs/quickstart-container.md %}).

---

## Prerequisites

### Required Software

The following packages must be installed on your **Fedora Linux** host. The `Prepare_LiveMedia_Build.py` script installs most of them automatically (Step 4), but you can install them manually first:

```bash
sudo dnf install -y \
    git \
    vim \
    lorax \
    pykickstart \
    anaconda \
    sshfs \
    python3-pyyaml \
    rsync \
    httpd
```

On **Fedora 42+**, also install:

```bash
sudo dnf install -y util-linux-script
```

| Package | Purpose |
|:--------|:--------|
| **git** | Clone the repository. |
| **vim** | Edit kickstart and config files (substitute your preferred editor). |
| **lorax** | Provides `livemedia-creator`, the tool that builds the live ISO. |
| **pykickstart** | Provides `ksflatten` to resolve `%include` directives in kickstarts. |
| **anaconda** | Required by `livemedia-creator --no-virt` for the install process. |
| **sshfs** | Mounting remote filesystems if needed during the build. |
| **python3-pyyaml** | Required by `Update_Remix_Config.sh` for safe YAML edits. |
| **rsync** | Used by prepare scripts to synchronize kickstart files into the build directory. |
| **httpd** | Apache HTTP server — `Prepare_Web_Files.py` stages files under `/var/www/html/` and the build fetches patches from localhost. |
| **util-linux-script** | `script` command used by the enhanced build script (Fedora 42+). |

### System Requirements

- **Operating System:** Fedora Linux (current supported releases)
- **Disk Space:** At least 25 GB free (for packages, build workspace, and ISO output)
- **Memory:** 4 GB minimum, 8 GB recommended
- **CPU:** Multi-core recommended (build is CPU-intensive)
- **Internet:** Required for downloading packages during the build
- **User Account:** Regular user with sudo privileges

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

## Quick Start

You have two options: the **automated script** (recommended, fewer steps) or the **manual path** (same operations, run individually).

---

### Option A: Automated Script (Recommended)

After cloning and configuring, `Build_LiveMedia_Physical.sh` handles everything — it updates `Setup/config.yml`, runs both prepare scripts, and launches the build.

#### Step 1: Clone the Repository

```bash
git clone https://github.com/tmichett/FedoraRemix-LiveMedia.git
cd FedoraRemix-LiveMedia
```

#### Step 2: Configure with `Update_Remix_Config.sh`

```bash
./Update_Remix_Config.sh
```

This interactive script sets values in both `config.yml` and `Setup/config.yml`:

| Prompt | What it sets | Notes |
|:-------|:-------------|:------|
| **SSH_Key_Location** | SSH key path | e.g. `~/.ssh/github_id` |
| **Fedora_Remix_Location** | Host output directory | e.g. `/home/youruser/Remix_Builder` |
| **GitHub_Registry_Owner** | GHCR namespace | Keep `tmichett` if using published images later |
| **Fedora version** | `Fedora_Version` / `fedora_version` in both configs | e.g. `44` |
| **PXE boot files** | `include_pxeboot_files` in `Setup/config.yml` | Answer **no** unless you need PXE network boot |

Press Enter at any prompt to keep the current value in brackets.

See [Configuration — Update_Remix_Config.sh]({% link docs/configuration.md %}#update_remix_configsh) for the full field reference.

#### Step 3: Run the Build

```bash
./Build_LiveMedia_Physical.sh
```

The script will:

1. Prompt for the Fedora release (or accept your `Setup/config.yml` value).
2. Show a kickstart selection menu (or pass `-k FedoraRemix` to skip).
3. Display a build summary and ask for confirmation.
4. Run `sudo python3 Prepare_LiveMedia_Build.py` — installs lorax, anaconda, pykickstart, and copies kickstart files to `/livemedia-creator/FedoraRemix/`.
5. Run `sudo python3 Prepare_Web_Files.py` — installs httpd, stages patches and files under `/var/www/html/`.
6. Run `LiveMedia_Enhanced_Build_Script.sh` under `/livemedia-creator/FedoraRemix/` — the actual `livemedia-creator` build.

**Command-line options:**

| Option | Purpose |
|:-------|:--------|
| `-v 44` | Set Fedora version without prompt |
| `-k FedoraRemix` | Choose kickstart without menu |
| `-l` | List available kickstart files and exit |
| `-h` | Show help |

#### Step 4: Retrieve the ISO

```bash
ls -lh /livemedia-creator/result/images/*.iso
```

The ISO name follows the pattern `<kickstart>-f<version>-x86_64.iso` (e.g. `FedoraRemix-f44-x86_64.iso`).

Then skip to [Testing Your ISO](#testing-your-iso).

---

### Option B: Manual Steps

If you prefer to run each step individually.

#### Step 1: Clone the Repository

```bash
git clone https://github.com/tmichett/FedoraRemix-LiveMedia.git
cd FedoraRemix-LiveMedia
```

#### Step 2: Install Required Packages

```bash
sudo dnf install -y git vim lorax pykickstart anaconda sshfs python3-pyyaml rsync httpd
```

On Fedora 42+:

```bash
sudo dnf install -y util-linux-script
```

#### Step 3: Configure

Run the interactive helper:

```bash
./Update_Remix_Config.sh
```

Or manually edit both config files to match:

**`config.yml`** (root):

```yaml
Container_Properties:
  Fedora_Version: "44"
  SSH_Key_Location: "~/.ssh/github_id"
  Fedora_Remix_Location: "/home/youruser/Remix_Builder"
  GitHub_Registry_Owner: "tmichett"
```

**`Setup/config.yml`**:

```yaml
fedora_version: 44
web_root: "/var/www/html"
include_pxeboot_files: false
```

`fedora_version` in `Setup/config.yml` **must match** `Fedora_Version` in the root `config.yml`.

#### Step 4: Prepare the Build Environment

Run from the `Setup/` directory, in this order:

**4a. Prepare the build directory:**

```bash
cd Setup
sudo python3 Prepare_LiveMedia_Build.py
```

This installs lorax, anaconda, pykickstart, and related packages, then creates `/livemedia-creator/FedoraRemix/` and copies kickstart files, build scripts, and config into it.

**4b. Prepare web files and patches:**

```bash
sudo python3 Prepare_Web_Files.py
```

This installs httpd, copies build patches and files to `/var/www/html/`, and optionally downloads PXE boot images if `include_pxeboot_files` is `true`.

Always run **4a then 4b** — the build script expects patches under `/var/www/html/`.

#### Step 5: Verify Apache is Running

The build fetches patches from localhost via httpd:

```bash
sudo systemctl start httpd
sudo systemctl enable httpd
curl -s http://localhost/ > /dev/null && echo "httpd OK" || echo "httpd FAILED"
```

#### Step 6: Customize (Optional)

The kickstart files are now in `/livemedia-creator/FedoraRemix/`. Edit them before building:

**Packages:**

```bash
sudo vim /livemedia-creator/FedoraRemix/FedoraRemixPackages.ks
```

Add packages (one per line) or comment out unwanted ones with `#`.

**System configuration:**

```bash
sudo vim /livemedia-creator/FedoraRemix/FedoraRemix.ks
```

Customize user accounts, network, firewall, SELinux, post-install scripts, etc.

#### Step 7: Build the ISO

```bash
cd /livemedia-creator/FedoraRemix
sudo ./LiveMedia_Enhanced_Build_Script.sh
```

For a variant kickstart:

```bash
sudo env REMIX_KICKSTART=FedoraRemixCosmic ./LiveMedia_Enhanced_Build_Script.sh
```

**Build process:**

1. Resolves the kickstart with `ksflatten`.
2. Runs `livemedia-creator` with `--no-virt` mode.
3. Installs packages (~15–30 minutes).
4. Runs post-installation scripts and creates the ISO (~10–20 minutes).
5. Renames `images/boot.iso` to `images/<kickstart>-f<ver>-x86_64.iso`.

#### Step 8: Retrieve the ISO

```bash
ls -lh /livemedia-creator/result/images/*.iso
```

---

## Testing Your ISO

1. **Verify it exists:**

   ```bash
   ls -lh /livemedia-creator/result/images/*.iso
   ```

2. **Test in a VM:**
   - Use **virt-manager**, GNOME Boxes, or VirtualBox
   - Attach the ISO and boot from it
   - Test the live environment and installation

3. **Create a bootable USB:**

   ```bash
   sudo dd if=/livemedia-creator/result/images/FedoraRemix-f44-x86_64.iso \
           of=/dev/sdX bs=4M status=progress
   ```

   Replace `/dev/sdX` with your USB device and the ISO path with your actual file.

---

## Building Different Variants

```bash
./Build_LiveMedia_Physical.sh -k FedoraRemixCosmic
./Build_LiveMedia_Physical.sh -k FedoraRemixTiny
```

Or omit `-k` to get the interactive kickstart menu.

---

## Troubleshooting

### httpd Not Running

**Problem:** Build fails fetching files from localhost.

**Solution:**

```bash
sudo systemctl start httpd
sudo systemctl enable httpd
```

### livemedia-creator Not Found

**Problem:** `command not found: livemedia-creator`

**Solution:** Install lorax:

```bash
sudo dnf install -y lorax
```

### SELinux Relabeling Errors

**Problem:** `setfiles: Could not set context` during the build.

**Solution:** Ensure `osbuild-selinux` is installed:

```bash
sudo dnf install -y osbuild-selinux
```

Pull the latest repo changes (the build applies SELinux patches automatically):

```bash
git pull origin main
cd Setup
sudo python3 Prepare_Web_Files.py
```

### Insufficient Disk Space

**Problem:** Build fails with not enough space.

**Solution:** Ensure at least 25 GB free. Clean old builds:

```bash
sudo rm -rf /livemedia-creator/result/images/*.iso
sudo dnf clean all
```

### Version Mismatch

**Problem:** Prepare or build scripts complain about mismatched Fedora versions.

**Solution:** Run `./Update_Remix_Config.sh` to set both configs to the same version, or manually ensure `Fedora_Version` in `config.yml` matches `fedora_version` in `Setup/config.yml`.

---

## Comparison: Physical vs Container

| Feature | Physical / VM | Container |
|:--------|:--------------|:----------|
| **Setup time** | Longer (install packages on host) | Faster (pull image) |
| **Host changes** | Installs lorax, anaconda, httpd on your system | Contained, no host modifications |
| **Isolation** | Less (modifies host) | More (everything in the container) |
| **Flexibility** | Full control over the build system | Standardized environment |
| **Best for** | Dedicated build machines, development | Quick reproducible builds, CI/CD |

---

## See Also

- [Configuration]({% link docs/configuration.md %}) — `config.yml`, `Setup/config.yml`, and `Update_Remix_Config.sh` reference
- [Quickstart (container)]({% link docs/quickstart-container.md %}) — building with Podman
- [Build scripts]({% link docs/build-scripts.md %}) — script reference
- [Troubleshooting]({% link docs/troubleshooting.md %})
