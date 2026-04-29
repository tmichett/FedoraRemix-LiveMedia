#!/bin/bash
#
# Verify_Build_LiveMedia.sh
# Pre-flight for FedoraRemix-LiveMedia: show config, optional Fedora version edit,
# PXE toggle, container image check, then optionally run Build_LiveMedia.sh
#

set -e

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

readonly CHECKMARK="✅"
readonly CROSS="❌"
readonly WARNING="⚠️"
readonly INFO="ℹ️"
readonly ROCKET="🚀"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_CONFIG="$SCRIPT_DIR/Setup/config.yml"
CONTAINER_CONFIG="$SCRIPT_DIR/config.yml"

print_message() {
    local level="$1"
    local message="$2"
    case "$level" in
        SUCCESS) echo -e "${GREEN}${CHECKMARK} ${message}${NC}" ;;
        ERROR)   echo -e "${RED}${CROSS} ${message}${NC}" ;;
        WARNING) echo -e "${YELLOW}${WARNING} ${message}${NC}" ;;
        INFO)    echo -e "${CYAN}${INFO} ${message}${NC}" ;;
        HEADER)
            echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${BOLD}${CYAN}║${NC} ${WHITE}${message}${NC}"
            echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
            ;;
    esac
}

get_container_field() {
    local key="$1"
    if [ ! -f "$CONTAINER_CONFIG" ]; then
        return 1
    fi
    grep -A 30 "Container_Properties:" "$CONTAINER_CONFIG" | grep "^[[:space:]]*${key}:" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | tr -d '"'
}

get_container_fedora_version() {
    get_container_field Fedora_Version || true
}

get_remix_fedora_version() {
    if [ ! -f "$SETUP_CONFIG" ]; then
        echo "ERROR: Setup/config.yml not found" >&2
        return 1
    fi
    local version
    version=$(grep "^fedora_version:" "$SETUP_CONFIG" | awk '{print $2}' | tr -d '"')
    if [ -z "$version" ]; then
        echo "ERROR: Could not extract fedora_version from Setup/config.yml" >&2
        return 1
    fi
    echo "$version"
}

get_github_registry_owner() {
    local owner
    owner=$(get_container_field GitHub_Registry_Owner)
    if [ -z "$owner" ]; then
        echo "ERROR: Could not extract GitHub_Registry_Owner" >&2
        return 1
    fi
    echo "$owner"
}

validate_fedora_version() {
    local v="$1"
    if [[ ! "$v" =~ ^[0-9]+$ ]]; then
        print_message "ERROR" "Fedora version must be a positive integer (got: '$v')"
        return 1
    fi
    if [ "$v" -lt 30 ] || [ "$v" -gt 99 ]; then
        print_message "ERROR" "Fedora version must be between 30 and 99 (got: $v)"
        return 1
    fi
    return 0
}

_yaml_set_container_field() {
    local key="$1" value="$2"
    python3 - "$CONTAINER_CONFIG" "$key" "$value" <<'PY'
import pathlib, re, sys

path = pathlib.Path(sys.argv[1])
key = sys.argv[2]
value = sys.argv[3]


def dq(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


text = path.read_text(encoding="utf-8")
pat = rf"(^[\t ]*){re.escape(key)}:[^\n]*"

def repl(m: re.Match) -> str:
    indent = m.group(1)
    return indent + key + ": " + dq(value)


after, count = re.subn(pat, repl, text, count=1, flags=re.MULTILINE)
if count != 1:
    sys.stderr.write(f"Error: Expected exactly one '{key}' under Container_Properties in {path}\n")
    sys.exit(1)
path.write_text(after, encoding="utf-8")
PY
}

write_container_fedora_version() {
    _yaml_set_container_field Fedora_Version "$1"
}

write_setup_fedora_version() {
    local v="$1"
    if ! grep -q '^fedora_version:' "$SETUP_CONFIG"; then
        print_message "ERROR" "No fedora_version: in $SETUP_CONFIG"
        return 1
    fi
    sed -i "s/^fedora_version:.*/fedora_version: ${v}/" "$SETUP_CONFIG"
}

normalize_yes_no() {
    local value
    value=$(echo "$1" | tr '[:upper:]' '[:lower:]' | xargs)
    case "$value" in
        y|yes|true|1|on)  echo "true" ;;
        n|no|false|0|off) echo "false" ;;
        *) return 1 ;;
    esac
}

get_include_pxeboot_setting() {
    if [ ! -f "$SETUP_CONFIG" ]; then
        return 1
    fi
    local raw
    raw=$(grep '^include_pxeboot_files:' "$SETUP_CONFIG" | awk '{print $2}' | tr -d '"' || true)
    if [ -z "$raw" ]; then
        return 1
    fi
    normalize_yes_no "$raw"
}

write_setup_include_pxeboot() {
    local value="$1"
    if grep -q '^include_pxeboot_files:' "$SETUP_CONFIG"; then
        sed -i "s/^include_pxeboot_files:.*/include_pxeboot_files: ${value}/" "$SETUP_CONFIG"
    else
        printf '\ninclude_pxeboot_files: %s\n' "$value" >> "$SETUP_CONFIG"
    fi
}

prompt_include_pxeboot() {
    local default="${1:-true}"
    local prompt_suffix="[Y/n]"
    [ "$default" = "false" ] && prompt_suffix="[y/N]"
    local input="" normalized=""
    while true; do
        read -r -p "$(echo -e "${BOLD}${WHITE}Include PXEBoot files in web assets? ${prompt_suffix}: ${NC}")" input
        if [ -z "$input" ]; then
            echo "$default"
            return
        fi
        normalized=$(normalize_yes_no "$input" || true)
        if [ -n "$normalized" ]; then
            echo "$normalized"
            return
        fi
        print_message "WARNING" "Please answer yes or no."
    done
}

check_container_image() {
    local image_name="$1"
    if podman image exists "$image_name" 2>/dev/null; then
        return 0
    elif sudo podman image exists "$image_name" 2>/dev/null; then
        return 0
    fi
    return 1
}

get_image_creation_date() {
    local image_name="$1"
    local date
    date=$(podman image inspect "$image_name" 2>/dev/null | grep -m 1 '"Created":' | awk -F'"' '{print $4}' | cut -d'T' -f1)
    if [ -z "$date" ]; then
        date=$(sudo podman image inspect "$image_name" 2>/dev/null | grep -m 1 '"Created":' | awk -F'"' '{print $4}' | cut -d'T' -f1)
    fi
    echo "$date"
}

prompt_new_fedora_version() {
    local default="$1"
    local input=""
    while true; do
        read -r -p "$(echo -e "${BOLD}${WHITE}Fedora version for both configs [${default}]: ${NC}")" input
        if [ -z "$input" ]; then
            echo "$default"
            return 0
        fi
        if validate_fedora_version "$input"; then
            echo "$input"
            return 0
        fi
    done
}

main() {
    echo ""
    print_message "HEADER" "🔍 Fedora Remix LiveMedia — Configuration Verification"
    echo ""

    print_message "INFO" "Reading configuration files..."
    echo ""

    CONTAINER_VERSION=$(get_container_fedora_version)
    if [ -z "$CONTAINER_VERSION" ]; then
        print_message "ERROR" "Failed to read Fedora_Version from config.yml"
        exit 1
    fi

    if ! REMIX_VERSION=$(get_remix_fedora_version); then
        exit 1
    fi

    if ! GITHUB_OWNER=$(get_github_registry_owner); then
        exit 1
    fi

    echo -e "${BOLD}Current Fedora release:${NC}  config.yml → ${WHITE}${CONTAINER_VERSION}${NC}   Setup/config.yml → ${WHITE}${REMIX_VERSION}${NC}"
    echo ""
    read -p "$(echo -e "${BOLD}${WHITE}Update Fedora version in config.yml + Setup/config.yml? [y/N]: ${NC}")" -n 1 -r
    echo ""
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        NEW_VER=$(prompt_new_fedora_version "${CONTAINER_VERSION}")
        write_container_fedora_version "$NEW_VER"
        write_setup_fedora_version "$NEW_VER"
        CONTAINER_VERSION="$NEW_VER"
        REMIX_VERSION="$NEW_VER"
        print_message "SUCCESS" "Both configs set to Fedora ${NEW_VER}"
        echo ""
    fi

    local include_pxeboot
    if [ -n "${REMIX_INCLUDE_PXEBOOT:-}" ]; then
        include_pxeboot=$(normalize_yes_no "${REMIX_INCLUDE_PXEBOOT}" || true)
        if [ -z "$include_pxeboot" ]; then
            print_message "ERROR" "Invalid REMIX_INCLUDE_PXEBOOT: ${REMIX_INCLUDE_PXEBOOT}"
            exit 1
        fi
    else
        include_pxeboot=$(get_include_pxeboot_setting || true)
        if [ -z "$include_pxeboot" ]; then
            print_message "INFO" "No include_pxeboot_files in Setup/config.yml — prompt."
            include_pxeboot=$(prompt_include_pxeboot "true")
            write_setup_include_pxeboot "$include_pxeboot"
            print_message "SUCCESS" "Saved include_pxeboot_files: ${include_pxeboot}"
        fi
    fi

    IMAGE_NAME="ghcr.io/${GITHUB_OWNER}/fedora-livemedia-builder:${CONTAINER_VERSION}"

    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║${NC} ${WHITE}Configuration Summary${NC}                                                ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${GREEN}Container${NC} (config.yml)                                             ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}    Fedora_Version: ${WHITE}${CONTAINER_VERSION}${NC}                                      ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}    Image: ${WHITE}${IMAGE_NAME}${NC}"
    printf "${BOLD}${CYAN}║${NC}\n"
    echo -e "${BOLD}${CYAN}║${NC}  ${GREEN}Kickstart / livemedia${NC} (Setup/config.yml)                          ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}    fedora_version: ${WHITE}${REMIX_VERSION}${NC}                                         ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}    include_pxeboot_files: ${WHITE}${include_pxeboot}${NC}                              ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}    Boot ISO name pattern: ${WHITE}images/<kickstart>-f${REMIX_VERSION}-x86_64.iso${NC}   ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}║${NC}                                                                      ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ "$CONTAINER_VERSION" != "$REMIX_VERSION" ]; then
        print_message "WARNING" "Version mismatch: config.yml (${CONTAINER_VERSION}) vs Setup/config.yml (${REMIX_VERSION})"
        echo -e "  ${YELLOW}Answer 'y' at the Fedora version prompt next time, or run ./Update_Remix_Config.sh${NC}"
        echo ""
    else
        print_message "SUCCESS" "Container and Setup/config.yml both use Fedora ${CONTAINER_VERSION}"
        echo ""
    fi

    print_message "INFO" "Checking for local container image..."
    if check_container_image "$IMAGE_NAME"; then
        IMAGE_DATE=$(get_image_creation_date "$IMAGE_NAME")
        print_message "SUCCESS" "Image found locally"
        if [ -n "$IMAGE_DATE" ]; then
            echo -e "  ${CYAN}Created: ${IMAGE_DATE}${NC}"
        fi
        echo ""
    else
        print_message "WARNING" "Image not found locally: ${IMAGE_NAME}"
        echo -e "  ${YELLOW}Build it: ${CYAN}./build.sh${NC}   or pull from ghcr.io after publish."
        echo ""
    fi

    if [ ! -f "$SCRIPT_DIR/Build_LiveMedia.sh" ]; then
        print_message "ERROR" "Build_LiveMedia.sh not found in $SCRIPT_DIR"
        exit 1
    fi
    if [ ! -x "$SCRIPT_DIR/Build_LiveMedia.sh" ]; then
        chmod +x "$SCRIPT_DIR/Build_LiveMedia.sh"
        print_message "INFO" "Made Build_LiveMedia.sh executable"
        echo ""
    fi

    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║${NC} ${WHITE}Ready to Build${NC}                                                       ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    read -p "$(echo -e "${BOLD}${WHITE}Run ./Build_LiveMedia.sh now? [y/N]: ${NC}")" -n 1 -r
    echo ""
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_message "SUCCESS" "Starting build..."
        echo ""
        print_message "INFO" "REMIX_INCLUDE_PXEBOOT=${include_pxeboot}"
        echo ""
        exec env REMIX_INCLUDE_PXEBOOT="$include_pxeboot" "$SCRIPT_DIR/Build_LiveMedia.sh"
    else
        print_message "INFO" "Cancelled."
        echo ""
        echo -e "${BOLD}Later:${NC}  ${CYAN}./Build_LiveMedia.sh${NC}  or  ${CYAN}./Verify_Build_LiveMedia.sh${NC}"
        echo -e "${BOLD}Full config editor:${NC}  ${CYAN}./Update_Remix_Config.sh${NC}"
        echo ""
        exit 0
    fi
}

main "$@"
