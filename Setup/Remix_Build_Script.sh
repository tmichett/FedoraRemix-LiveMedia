#!/usr/bin/bash
#
# Minimal one-shot build: livemedia-creator, default FedoraRemix.ks
# For full output and error handling, use ./LiveMedia_Enhanced_Build_Script.sh
#

get_fedora_version() {
    if [ -f "config.yml" ]; then
        local version
        version=$(grep '^fedora_version:' config.yml | awk '{print $2}' | tr -d '"')
        [ -n "$version" ] && echo "$version" && return
    fi
    echo "43"
}

set -e
setenforce 0

FEDORA_VERSION=$(get_fedora_version)
KS="FedoraRemix.ks"
[ -n "${REMIX_KICKSTART:-}" ] && KS="${REMIX_KICKSTART}.ks"
LOG="LiveMedia-Quick-$(date +%m%d%y-%H%M).log"

VOLD="FEDORA_REMIX_${FEDORA_VERSION}"
if [ -n "${REMIX_KICKSTART:-}" ] && [ "${REMIX_KICKSTART}" != "FedoraRemix" ]; then
    SUFF=$(echo "${REMIX_KICKSTART}" | sed 's/FedoraRemix//')
    SUFFU=$(echo "$SUFF" | tr '[:lower:]' '[:upper:]')
    VOLD="FEDORA_${SUFFU}_${FEDORA_VERSION}"
fi

LMC_RESULT_DIR="/livemedia-creator/result"
LMC_TMP="/livemedia-creator/tmp"
KS_ABS=$(readlink -f "$KS")
FLAT_KS="${LMC_TMP}/lmc-flattened-quick.ks"
mkdir -p "$LMC_TMP"
ksflatten -c "$KS_ABS" -o "$FLAT_KS"
rm -rf "$LMC_RESULT_DIR"
# Same dracut --add as LiveMedia_Enhanced (smaller set; Lorax default often breaks)
script -c "livemedia-creator --ks=\"$FLAT_KS\" --no-virt --make-iso --resultdir=\"$LMC_RESULT_DIR\" --tmp=$LMC_TMP --volid=\"$VOLD\" --project \"Fedora Remix\" --releasever \"$FEDORA_VERSION\" --macboot --dracut-arg=--xz --dracut-arg=\"--add livenet dmsquash-live pollcdrom\" --dracut-arg=--no-hostonly --dracut-arg=--debug --dracut-arg=--no-early-microcode 2>&1" "$LOG"
