#!/bin/bash
set -e

# Push fedora-livemedia-builder to ghcr.io (same pattern as RemixBuilder/push.sh).

if [ ! -f "config.yml" ]; then
    echo "Error: config.yml not found"
    exit 1
fi

FEDORA_VERSION=$(grep -A 12 "Container_Properties:" config.yml | grep "Fedora_Version:" | awk '{print $2}' | tr -d '"')
GITHUB_REGISTRY_OWNER=$(grep -A 12 "Container_Properties:" config.yml | grep "GitHub_Registry_Owner:" | awk '{print $2}' | tr -d '"')

if [ -z "$FEDORA_VERSION" ] || [ -z "$GITHUB_REGISTRY_OWNER" ]; then
    echo "Error: Could not read Fedora_Version / GitHub_Registry_Owner from config.yml"
    exit 1
fi

IMAGE_NAME="ghcr.io/${GITHUB_REGISTRY_OWNER}/fedora-livemedia-builder:${FEDORA_VERSION}"

if [[ "$IMAGE_NAME" != ghcr.io/* ]]; then
    echo "Error: expected ghcr.io image, got: $IMAGE_NAME"
    exit 1
fi

if ! podman images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${IMAGE_NAME}$"; then
    echo "Error: local image not found: $IMAGE_NAME"
    echo "Build first: ./build.sh"
    exit 1
fi

echo "Logging in to ghcr.io..."
podman login ghcr.io

echo "Pushing $IMAGE_NAME"
podman push "$IMAGE_NAME"

echo "Done. Pull elsewhere: podman pull $IMAGE_NAME"
