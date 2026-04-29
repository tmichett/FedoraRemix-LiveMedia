# FedoraRemix-LiveMedia

Build a **bootable live ISO** from the same `Setup/Kickstarts` and assets as [Fedora_Remix](https://github.com/tmichett/Fedora_Remix), using **`livemedia-creator`** (`lorax` package) on a Fedora host.

- Work dir after prepare: **`/livemedia-creator/FedoraRemix`**
- Output ISO: **`/livemedia-creator/result/`**
- Build script: **`Setup/LiveMedia_Enhanced_Build_Script.sh`**

## Quick start

1. Set **`Setup/config.yml`** (`fedora_version`, `include_pxeboot_files` if you use `Prepare_Web_Files.py`).
2. From the repo root:

   `./Build_LiveMedia_Physical.sh`

   (optional: `-k` kickstart, `-v` version — see `Build_LiveMedia_Physical.sh -h`)

3. Pick up the `.iso` from **`/livemedia-creator/result/`** when the run finishes.

Manual equivalent: `cd Setup && sudo python3 ./Prepare_LiveMedia_Build.py`, then `sudo python3 ./Prepare_Web_Files.py`, then `cd /livemedia-creator/FedoraRemix && sudo env REMIX_KICKSTART=YourName ./LiveMedia_Enhanced_Build_Script.sh`.

`Prepare_LiveMedia_Build.py` installs **lorax**, **pykickstart** (`ksflatten` flattens `%include` for anaconda), and common helpers. The build uses **`--no-virt --make-iso`**.

**If a previous run died:** you may need `sudo rm -f /run/user/0/anaconda.pid` before retrying, or the script will clear a stale file when safe.

**If `dracut` fails** during the ISO step, check `program.log` under the `lmc-work-*` tree in `/livemedia-creator/tmp` for that run.

## Container (optional)

`Build_LiveMedia.sh` is Podman-based; output mount is `/livemedia-creator`. You need a builder image that has **lorax** and can run the script in that tree (not the old livecd-creator image).

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
