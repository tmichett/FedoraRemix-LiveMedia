#!/usr/bin/bash
#
# Travis Michette <tmichett@redhat.com>
# Alternative version using tee instead of script command

## Script used to create LiveISO for the FedoraRemix based on the KS

# Function to read Fedora version from config.yml
get_fedora_version() {
    local config_file="config.yml"
    if [ -f "$config_file" ]; then
        # Extract fedora_version from YAML using grep and awk
        local version=$(grep '^fedora_version:' "$config_file" | awk '{print $2}' | tr -d '"')
        if [ -n "$version" ]; then
            echo "$version"
        else
            echo "42"  # fallback default
        fi
    else
        echo "42"  # fallback default if config file not found
    fi
}

# Get version from config
FEDORA_VERSION=$(get_fedora_version)

setenforce 0

rm -rf /livemedia-creator/result
mkdir -p /livemedia-creator/tmp
FLAT_KS="/livemedia-creator/tmp/lmc-flattened-simple.ks"
KS_ABS=$(readlink -f FedoraRemix.ks)
ksflatten -c "$KS_ABS" -o "$FLAT_KS"
livemedia-creator --ks="$FLAT_KS" --no-virt --make-iso --resultdir=/livemedia-creator/result \
  --tmp=/livemedia-creator/tmp --volid="FEDORA_REMIX_${FEDORA_VERSION}" \
  --project "Fedora Remix" --releasever "$FEDORA_VERSION" --macboot \
  --dracut-arg=--xz --dracut-arg="--add livenet dmsquash-live pollcdrom" \
  --dracut-arg=--no-hostonly --dracut-arg=--debug --dracut-arg=--no-early-microcode \
  2>&1 | tee "FedoraBuild-$(date +%m%d%y-%H%M).out"
