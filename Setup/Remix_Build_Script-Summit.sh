#!/usr/bin/bash
#
# Travis Michette <tmichett@redhat.com>

## LiveMedia variant: Summit kickstart

get_fedora_version() {
    if [ -f "config.yml" ]; then
        local v
        v=$(grep '^fedora_version:' config.yml | awk '{print $2}' | tr -d '"')
        [ -n "$v" ] && echo "$v" && return
    fi
    echo "43"
}
FEDORA_VERSION=$(get_fedora_version)

setenforce 0

rm -rf /livemedia-creator/result
mkdir -p /livemedia-creator/tmp
FLAT_KS="/livemedia-creator/tmp/lmc-flattened-summit.ks"
KS_ABS=$(readlink -f FedoraRemix-Summit.ks)
ksflatten -c "$KS_ABS" -o "$FLAT_KS"
livemedia-creator --ks="$FLAT_KS" --no-virt --make-iso --resultdir=/livemedia-creator/result \
  --tmp=/livemedia-creator/tmp --volid="SUMMIT_FEDORA_RMX_2025" \
  --project "Fedora Remix" --releasever "$FEDORA_VERSION" --macboot \
  --dracut-arg=--xz --dracut-arg="--add livenet dmsquash-live pollcdrom" \
  --dracut-arg=--no-hostonly --dracut-arg=--debug --dracut-arg=--no-early-microcode \
  2>&1 | tee "FedoraBuildi-$(date +%m%d%y-%H%M).out"

