# FedoraRemix-LiveMedia

Build a **bootable live ISO** from the same `Setup/Kickstarts` and assets as [Fedora_Remix](https://github.com/tmichett/Fedora_Remix), using **`livemedia-creator`** (`lorax` package) on a Fedora host.

- Work dir after prepare: **`/livemedia-creator/FedoraRemix`**
- Output ISO: **`/livemedia-creator/result/`**
- Build script: **`Setup/LiveMedia_Enhanced_Build_Script.sh`**

## Quick start

1. Set **`Setup/config.yml`** and repo **`config.yml`** (`fedora_version` / `Fedora_Version`, paths, PXE). **`./Update_Remix_Config.sh`** walks through all fields interactively.
2. From the repo root:

   **`./Verify_Build_LiveMedia.sh`** (recommended) — shows both YAML versions, optionally **updates Fedora release in both files**, checks for **`fedora-livemedia-builder`** locally, then offers to run **`./Build_LiveMedia.sh`**.

   Or build without the verifier: **`./Build_LiveMedia_Physical.sh`** on the host (optional: `-k` kickstart, `-v` version — see `-h`).

3. Pick up the `.iso` from **`/livemedia-creator/result/`** when the run finishes.

Manual equivalent: `cd Setup && sudo python3 ./Prepare_LiveMedia_Build.py`, then `sudo python3 ./Prepare_Web_Files.py`, then `cd /livemedia-creator/FedoraRemix && sudo env REMIX_KICKSTART=YourName ./LiveMedia_Enhanced_Build_Script.sh`.

`Prepare_LiveMedia_Build.py` installs **lorax**, **pykickstart** (`ksflatten` flattens `%include` for anaconda), and common helpers. The build uses **`--no-virt --make-iso`**.

**If a previous run died:** you may need `sudo rm -f /run/user/0/anaconda.pid` before retrying, or the script will clear a stale file when safe.

**If `dracut` fails** during the ISO step, check `program.log` under the `lmc-work-*` tree in `/livemedia-creator/tmp` for that run.

## Container (Podman)

Same layout as [RemixBuilder](https://github.com/tmichett/RemixBuilder) (livecd-creator), but this image runs **livemedia-creator**.

| File | Purpose |
|------|---------|
| `Verify_Build_LiveMedia.sh` | Pre-flight: optional **Fedora version** for both configs, PXE prompt, image check, then **`Build_LiveMedia.sh`** |
| `Containerfile` | `fedora:${FEDORA_VERSION}` + lorax, anaconda, pykickstart, httpd, systemd, etc. |
| `entrypoint.sh` | `Prepare_Web_Files.py` → `Prepare_LiveMedia_Build.py` → `LiveMedia_Enhanced_Build_Script.sh` |
| `build.sh` / `push.sh` | Build and push `ghcr.io/<owner>/fedora-livemedia-builder:<ver>` from `config.yml` |
| `ssh_config` | Git SSH using `/root/github_id` in the container |
| `Build_LiveMedia.sh` | Run the container (mounts repo, output dir, key) |

From repo root:

1. `./build.sh` — builds the image tag declared in `config.yml` (`Container_Properties`).
2. `./Verify_Build_LiveMedia.sh` or `./Build_LiveMedia.sh` — verify then build, or build directly (detached log follow by default, or `-a` for interactive).

Output on the host stays under the directory you set as `Fedora_Remix_Location` (mounted at `/livemedia-creator` in the container).

## Config files

- **`config.yml`** (repo root): paths / registry for `Build_LiveMedia.sh`.
- **`Setup/config.yml`:** `fedora_version`, PXE-related flags for the web prep script.

| Script | Role |
|--------|------|
| `Build_LiveMedia_Physical.sh` | Prepare + optional web + ISO build |
| `Build_LiveMedia.sh` | Podman |
| `Update_Remix_Config.sh` | Edit both config files |
| `Setup/Prepare_LiveMedia_Build.py` | Install packages, sync kickstarts |
| `Setup/LiveMedia_Enhanced_Build_Script.sh` | Main `livemedia-creator` run |
