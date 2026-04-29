#!/bin/bash
set -e

# For Build_LiveMedia.sh: write ok / failed:N so the host can stop tailing
ENTRYPOINT_STATUS_FILE=/tmp/entrypoint-status
ENTRYPOINT_SUCCESS=''
on_exit() {
  local st=$?
  if [ -n "$ENTRYPOINT_SUCCESS" ]; then
    echo "ok" > "$ENTRYPOINT_STATUS_FILE"
    touch /tmp/entrypoint-completed
  else
    echo "failed:${st}" > "$ENTRYPOINT_STATUS_FILE"
  fi
}
trap on_exit EXIT

export PYTHONUNBUFFERED=1
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

exec > >(tee -a /tmp/entrypoint.log) 2>&1

echo "Build output: this stream + /tmp/entrypoint.log  |  journalctl -u livemedia-builder.service -f"

echo "Configuring DNF..."
if ! grep -q "max_parallel_downloads" /etc/dnf/dnf.conf 2>/dev/null; then
    echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
fi
if ! grep -q "fastestmirror" /etc/dnf/dnf.conf 2>/dev/null; then
    echo "fastestmirror=True" >> /etc/dnf/dnf.conf
fi
dnf clean all 2>/dev/null || true

echo "DEBUG: REMIX_KICKSTART='${REMIX_KICKSTART:-}' REMIX_INCLUDE_PXEBOOT='${REMIX_INCLUDE_PXEBOOT:-}'"
env | grep -iE 'remix|pxe' || true

if [ -z "${REMIX_KICKSTART:-}" ] && [ -f /tmp/remix_kickstart.txt ]; then
    REMIX_KICKSTART=$(cat /tmp/remix_kickstart.txt)
    echo "Read REMIX_KICKSTART from /tmp/remix_kickstart.txt: ${REMIX_KICKSTART}"
fi

REMIX_KICKSTART="${REMIX_KICKSTART:-FedoraRemix}"
export REMIX_KICKSTART
# Build_LiveMedia.sh bind-mounts host temp file here as :ro — do not open for write (avoids "Permission denied").
if [ ! -e /tmp/remix_kickstart.txt ] || [ -w /tmp/remix_kickstart.txt ]; then
    echo "$REMIX_KICKSTART" > /tmp/remix_kickstart.txt
fi

echo "Selected kickstart: ${REMIX_KICKSTART}  (REMIX_INCLUDE_PXEBOOT=${REMIX_INCLUDE_PXEBOOT:-<unset, Prepare_Web_Files uses Setup/config.yml>})"

echo "Waiting for /root/workspace..."
for _ in {1..30}; do
    if [ -d "/root/workspace" ] && [ "$(ls -A /root/workspace 2>/dev/null)" ]; then
        break
    fi
    sleep 1
done
if [ ! -d "/root/workspace" ]; then
    echo "Error: /root/workspace not found"
    exit 1
fi

cd ~/workspace/Setup
if [ ! -f "Prepare_Web_Files.py" ]; then
    echo "Error: Prepare_Web_Files.py not in /root/workspace/Setup"
    ls -la /root/workspace/Setup
    exit 1
fi
if [ ! -f "Prepare_LiveMedia_Build.py" ]; then
    echo "Error: Prepare_LiveMedia_Build.py not in /root/workspace/Setup"
    ls -la /root/workspace/Setup
    exit 1
fi

echo "Loading SELinux policy modules (osbuild / chroot relabel)..."
for pp_file in /usr/share/selinux/packages/*.pp; do
    [ -f "$pp_file" ] && semodule -i "$pp_file" 2>/dev/null && echo "  Loaded: $(basename "$pp_file")" || true
done

echo "Running: python3 Prepare_Web_Files.py"
python3 Prepare_Web_Files.py

echo "Running: python3 Prepare_LiveMedia_Build.py"
python3 Prepare_LiveMedia_Build.py

cd /livemedia-creator/FedoraRemix
if [ ! -f "LiveMedia_Enhanced_Build_Script.sh" ]; then
    echo "Error: LiveMedia_Enhanced_Build_Script.sh not in /livemedia-creator/FedoraRemix"
    exit 1
fi

echo "Running: ./LiveMedia_Enhanced_Build_Script.sh"
./LiveMedia_Enhanced_Build_Script.sh

echo ""
echo -e "\033[1;32m╔══════════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;32m║\033[0m \033[1;37mLiveMedia build finished.\033[0m                                                  \033[1;32m║\033[0m"
echo -e "\033[1;32m╚══════════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""
echo "Bootable image: /livemedia-creator/result/images/ (see LiveMedia script for renamed .iso)"
echo "Logs: /livemedia-creator/FedoraRemix/"
echo "Type exit or poweroff to stop the container."
echo ""

ENTRYPOINT_SUCCESS=1
