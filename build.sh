#!/bin/bash
set -e

# Build the fedora-livemedia-builder image (Podman). Reads config.yml like RemixBuilder/build.sh.

if [ ! -f "config.yml" ]; then
    echo "Error: config.yml not found in current directory"
    exit 1
fi

FEDORA_VERSION=$(grep -A 12 "Container_Properties:" config.yml | grep "Fedora_Version:" | awk '{print $2}' | tr -d '"')
GITHUB_REGISTRY_OWNER=$(grep -A 12 "Container_Properties:" config.yml | grep "GitHub_Registry_Owner:" | awk '{print $2}' | tr -d '"')

if [ -z "$FEDORA_VERSION" ]; then
    echo "Error: Could not extract Fedora_Version from config.yml"
    exit 1
fi
if [ -z "$GITHUB_REGISTRY_OWNER" ]; then
    echo "Error: Could not extract GitHub_Registry_Owner from config.yml"
    exit 1
fi

IMAGE_NAME="ghcr.io/${GITHUB_REGISTRY_OWNER}/fedora-livemedia-builder:${FEDORA_VERSION}"

echo "Building livemedia builder (Fedora ${FEDORA_VERSION})"
echo "Image: $IMAGE_NAME"

podman build \
    --build-arg "FEDORA_VERSION=${FEDORA_VERSION}" \
    -t "$IMAGE_NAME" \
    -f Containerfile .

echo ""
echo "Build complete: $IMAGE_NAME"
echo "Push: ./push.sh"
echo "Run:  ./Build_LiveMedia.sh"
