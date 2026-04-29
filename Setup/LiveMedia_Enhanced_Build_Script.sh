#!/usr/bin/bash
#
# Build a bootable live ISO with livemedia-creator (lorax).
# Travis Michette <tmichett@redhat.com>
#
# REMIX_KICKSTART: kickstart base name (e.g. FedoraRemixTiny), else FedoraRemix.ks

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

readonly CHECKMARK="✅"
readonly CROSS="❌"
readonly ARROW="➤"
readonly GEAR="⚙️"
readonly ROCKET="🚀"
readonly PACKAGE="📦"
readonly WRENCH="🔧"
readonly CLOCK="🕐"
readonly TARGET="🎯"
readonly STAR="⭐"

readonly BUILD_DATE=$(date +%m%d%y-%H%M)
readonly LMC_TMP="/livemedia-creator/tmp"
# lorax requires --resultdir to not exist (not the same tree as kickstarts/ working copy)
readonly LMC_RESULT_DIR="/livemedia-creator/result"

if [ -z "$REMIX_KICKSTART" ] && [ -f /tmp/remix_kickstart.txt ]; then
    REMIX_KICKSTART=$(cat /tmp/remix_kickstart.txt)
fi

if [ -n "$REMIX_KICKSTART" ]; then
    readonly BUILD_NAME="$REMIX_KICKSTART"
    readonly KS_FILE="${REMIX_KICKSTART}.ks"
else
    readonly BUILD_NAME="FedoraRemix"
    readonly KS_FILE="FedoraRemix.ks"
fi

readonly BUILD_LOG="${BUILD_NAME}-Build-${BUILD_DATE}.log"

get_fedora_version() {
    local config_file="config.yml"
    if [ -f "$config_file" ]; then
        local version
        version=$(grep '^fedora_version:' "$config_file" | awk '{print $2}' | tr -d '"')
        if [ -n "$version" ]; then
            echo "$version"
            return
        fi
    fi
    echo "43"
}

readonly FEDORA_VERSION=$(get_fedora_version)
if [ "$BUILD_NAME" = "FedoraRemix" ]; then
    readonly BUILD_TITLE="FEDORA_REMIX_${FEDORA_VERSION}"
else
    VARIANT_SUFFIX=$(echo "$BUILD_NAME" | sed 's/FedoraRemix//')
    VARIANT_UPPER=$(echo "$VARIANT_SUFFIX" | tr '[:lower:]' '[:upper:]')
    readonly BUILD_TITLE="FEDORA_${VARIANT_UPPER}_${FEDORA_VERSION}"
fi

readonly ISO_ARCH="$(uname -m)"
# Lorax always writes images/boot.iso; we rename in place to this basename (single file, no duplicate).
if [ -n "${REMIX_ISO_BASENAME:-}" ]; then
    readonly ISO_ARTIFACT_REL="$REMIX_ISO_BASENAME"
else
    readonly ISO_ARTIFACT_REL="${BUILD_NAME}-f${FEDORA_VERSION}-${ISO_ARCH}.iso"
fi
readonly ISO_ARTIFACT="${LMC_RESULT_DIR}/images/${ISO_ARTIFACT_REL}"

print_message() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local output=""

    case "$level" in
        "INFO")
            output="${BLUE}${ARROW}${NC} ${BOLD}[${timestamp}]${NC} ${message}"
            ;;
        "SUCCESS")
            output="${GREEN}${CHECKMARK}${NC} ${BOLD}[${timestamp}]${NC} ${GREEN}${message}${NC}"
            ;;
        "WARNING")
            output="${YELLOW}⚠️${NC} ${BOLD}[${timestamp}]${NC} ${YELLOW}${message}${NC}"
            ;;
        "ERROR")
            output="${RED}${CROSS}${NC} ${BOLD}[${timestamp}]${NC} ${RED}${message}${NC}"
            ;;
        "STAGE")
            output="\n${PURPLE}${STAR}═══════════════════════════════════════════════════════════════════════${NC}\n${PURPLE}${STAR}${NC} ${BOLD}${WHITE}$message${NC}\n${PURPLE}${STAR}═══════════════════════════════════════════════════════════════════════${NC}\n"
            ;;
        "HEADER")
            output="\n${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}\n${CYAN}║${NC} ${BOLD}${WHITE}$message${NC}${CYAN}║${NC}\n${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}\n"
            ;;
    esac

    echo -e "$output"
    if [ -n "$BUILD_LOG" ]; then
        echo -e "$output" | sed -r 's/\x1B\[[0-9;]*[mK]//g' >> "$BUILD_LOG"
    fi
}

check_prerequisites() {
    print_message "STAGE" "Checking build prerequisites"
    local missing_tools=()
    for tool in livemedia-creator ksflatten setenforce dnf; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_message "ERROR" "Missing required tools: ${missing_tools[*]} (e.g. dnf install -y lorax pykickstart)"
        exit 1
    fi
    if [ "$EUID" -ne 0 ]; then
        print_message "ERROR" "This script must be run as root"
        exit 1
    fi
    if [ ! -f "$KS_FILE" ]; then
        print_message "ERROR" "Kickstart file '$KS_FILE' not found in $(pwd)"
        exit 1
    fi
    print_message "SUCCESS" "All prerequisites satisfied"
}

prepare_environment() {
    print_message "STAGE" "Preparing build environment"
    print_message "INFO" "${GEAR} Setting SELinux to permissive for the build..."
    setenforce 0
    print_message "INFO" "${GEAR} Ensuring livemedia-creator temp directory exists: $LMC_TMP"
    mkdir -p "$LMC_TMP"
    local available_space
    available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_space" -lt 10 ] 2>/dev/null; then
        print_message "WARNING" "Low disk space in current filesystem: ${available_space}GB (recommend 10GB+)"
    else
        print_message "SUCCESS" "Sufficient disk space: ${available_space}GB available (working dir: $(pwd))"
    fi
}

show_build_info() {
    print_message "HEADER" "FEDORA REMIX — LIVEMEDIA-CREATOR"
    echo -e "${BOLD}Build configuration:${NC}"
    echo -e "  ${ARROW} Build / label: ${GREEN}$BUILD_NAME${NC}"
    echo -e "  ${ARROW} Kickstart:     ${GREEN}$KS_FILE${NC}"
    echo -e "  ${ARROW} ISO volid:     ${GREEN}$BUILD_TITLE${NC}"
    echo -e "  ${ARROW} releasever:    ${GREEN}$FEDORA_VERSION${NC}"
    echo -e "  ${ARROW} --tmp:         ${GREEN}$LMC_TMP${NC}"
    echo -e "  ${ARROW} --resultdir:   ${GREEN}$LMC_RESULT_DIR${NC} ${WHITE}(cleared before each run)${NC}"
    echo -e "  ${ARROW} Boot ISO name: ${GREEN}images/${ISO_ARTIFACT_REL}${NC} ${WHITE}(rename after build)${NC}"
    echo -e "  ${ARROW} Log:           ${GREEN}$BUILD_LOG${NC}"
    echo ""
}

# /run/user/0/anaconda.pid is left behind when anaconda (livemedia-creator --no-virt) is killed or dies
clear_stale_anaconda_pid() {
    local pidf="/run/user/${EUID}/anaconda.pid"
    [ -f "$pidf" ] || return 0
    local oldpid
    oldpid=$(tr -d ' \n' <"$pidf" 2>/dev/null || true)
    if [ -n "$oldpid" ] && kill -0 "$oldpid" 2>/dev/null; then
        print_message "ERROR" "anaconda is already running (pid ${oldpid}). Stop it, then retry. Refuse to remove: $pidf"
        return 1
    fi
    print_message "INFO" "${WRENCH} Removing stale anaconda lock file: $pidf (leftover from a crashed or interrupted run)"
    rm -f "$pidf" || {
        print_message "ERROR" "Could not remove $pidf (try: rm -f $pidf as root)"
        return 1
    }
    return 0
}

format_duration() {
    local total_seconds=$1
    local hours=$((total_seconds / 3600))
    local minutes=$(( (total_seconds % 3600) / 60 ))
    local seconds=$((total_seconds % 60))
    if [ $hours -gt 0 ]; then
        echo "${hours}h ${minutes}m ${seconds}s"
    elif [ $minutes -gt 0 ]; then
        echo "${minutes}m ${seconds}s"
    else
        echo "${seconds}s"
    fi
}

run_build() {
    print_message "STAGE" "livemedia-creator (make-iso, no-virt)"
    local ks_abs
    ks_abs=$(readlink -f "$KS_FILE")
    if [ -z "$ks_abs" ] || [ ! -f "$ks_abs" ]; then
        print_message "ERROR" "Could not resolve kickstart: $KS_FILE"
        return 1
    fi

    if [ -e "$LMC_RESULT_DIR" ]; then
        print_message "INFO" "${GEAR} Removing previous --resultdir (lorax needs it absent): $LMC_RESULT_DIR"
        rm -rf "$LMC_RESULT_DIR" || {
            print_message "ERROR" "Failed to remove $LMC_RESULT_DIR"
            return 1
        }
    fi
    mkdir -p "$(dirname "$LMC_RESULT_DIR")"
    mkdir -p "$LMC_TMP"

    # anaconda in --no-virt does not resolve %include relative to the top-level .ks path; flatten first
    local flat_ks
    flat_ks="${LMC_TMP}/lmc-flattened-${BUILD_NAME}.ks"
    print_message "INFO" "${WRENCH} Flattening kickstart (ksflatten) → $flat_ks"
    if ! ksflatten -c "$ks_abs" -o "$flat_ks"; then
        print_message "ERROR" "ksflatten failed; fix %include paths in $ks_abs and dependencies"
        return 1
    fi

    if ! clear_stale_anaconda_pid; then
        return 1
    fi

    # Dracut: small --add set so initrd rebuild usually succeeds in lmc (not Lorax’s full default).
    local dracut_add_mods="livenet dmsquash-live pollcdrom"

    {
        echo ""
        echo "================================================================"
        echo "FLATTEN: ksflatten -c $ks_abs -o $flat_ks"
        echo "DRACUT --add: $dracut_add_mods"
        echo "================================================================"
        echo ""
    } >> "$BUILD_LOG"
    print_message "INFO" "${ROCKET} livemedia-creator (make-iso) — see log for full command"

    exec 3>&1 4>&2
    exec > >(tee -a "$BUILD_LOG") 2>&1

    # --dracut-arg replaces pylorax defaults entirely. Values that start with "--" must use
    # --dracut-arg=... or the main parser treats them as livemedia-creator options and errors.
    livemedia-creator \
        --ks="$flat_ks" \
        --no-virt \
        --make-iso \
        --resultdir="$LMC_RESULT_DIR" \
        --tmp="$LMC_TMP" \
        --volid="$BUILD_TITLE" \
        --project "Fedora Remix" \
        --releasever="$FEDORA_VERSION" \
        --macboot \
        --dracut-arg=--xz \
        --dracut-arg="--add ${dracut_add_mods}" \
        --dracut-arg=--no-hostonly \
        --dracut-arg=--debug \
        --dracut-arg=--no-early-microcode
    local build_exit_code=$?

    exec 1>&3 2>&4
    exec 3>&- 4>&-
    return $build_exit_code
}

# Single boot image: mv images/boot.iso → images/<name>.iso and fix .treeinfo paths (no second copy).
finalize_named_iso() {
    local src="${LMC_RESULT_DIR}/images/boot.iso"
    local dest="$ISO_ARTIFACT"
    [ -f "$src" ] || return 0
    if [ "$src" = "$dest" ]; then
        return 0
    fi
    # Older script versions left a top-level hard link with the same basename; remove so du is not confusing
    rm -f "${LMC_RESULT_DIR}/${ISO_ARTIFACT_REL}" 2>/dev/null || true
    rm -f "$dest" 2>/dev/null || true
    if ! mv -f "$src" "$dest"; then
        print_message "WARNING" "Could not rename boot.iso → images/${ISO_ARTIFACT_REL}"
        return 1
    fi
    local ti="${LMC_RESULT_DIR}/.treeinfo"
    if [ -f "$ti" ]; then
        sed -i "s|images/boot\\.iso|images/${ISO_ARTIFACT_REL}|g" "$ti" 2>/dev/null || true
    fi
    print_message "INFO" "${PACKAGE} Boot image: images/${ISO_ARTIFACT_REL} (renamed from boot.iso; .treeinfo adjusted if present)"
}

# lorax puts the bootable image at images/boot.iso under --resultdir, not always as result/*.iso
resolve_build_iso() {
    local d="$1"
    if [ -n "${ISO_ARTIFACT:-}" ] && [ -f "$ISO_ARTIFACT" ]; then
        printf '%s' "$ISO_ARTIFACT"
        return 0
    fi
    if [ -f "${d}/images/boot.iso" ]; then
        printf '%s' "${d}/images/boot.iso"
        return 0
    fi
    local f
    f=$(ls -1t "${d}"/*.iso 2>/dev/null | head -1)
    if [ -n "$f" ]; then
        printf '%s' "$f"
        return 0
    fi
    f=$(find "${d}" -maxdepth 5 -type f -name '*.iso' 2>/dev/null | head -1)
    if [ -n "$f" ]; then
        printf '%s' "$f"
        return 0
    fi
    return 1
}

show_build_results() {
    local exit_code=$1
    local total_duration=$2
    print_message "STAGE" "Build results"
    if [ "$exit_code" -eq 0 ]; then
        print_message "SUCCESS" "${ROCKET} livemedia-creator completed successfully"
        echo ""
        echo -e "${CYAN}Total time: ${GREEN}$(format_duration "$total_duration")${NC}"
        local iso
        iso=$(resolve_build_iso "${LMC_RESULT_DIR}") || iso=""
        if [ -n "$iso" ]; then
            local iso_size
            iso_size=$(du -h "$iso" 2>/dev/null | cut -f1)
            print_message "SUCCESS" "${PACKAGE} ${iso} (${iso_size})"
        else
            print_message "WARNING" "No .iso found under ${LMC_RESULT_DIR}; check logs (kickstarts stay in $(pwd))"
        fi
        print_message "INFO" "${WRENCH} Full log: $BUILD_LOG"
    else
        print_message "ERROR" "${CROSS} Build failed (exit $exit_code)"
        print_message "INFO" "${WRENCH} See: $BUILD_LOG"
    fi
}

main() {
    local start_time
    start_time=$(date +%s)
    {
        echo "================================================================"
        echo "FEDORA REMIX LIVEMEDIA-CREATOR LOG — $(date)"
        echo "Script: LiveMedia_Enhanced_Build_Script.sh"
        echo "Working directory: $(pwd)"
        echo "User: $(whoami)"
        echo "================================================================"
        echo ""
    } > "$BUILD_LOG"

    print_message "HEADER" "FEDORA REMIX — LIVEMEDIA-CREATOR BUILD"
    check_prerequisites
    prepare_environment
    show_build_info
    run_build
    local build_result=$?
    if [ "$build_result" -eq 0 ]; then
        finalize_named_iso
    fi
    local end_time
    end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    show_build_results "$build_result" "$total_duration"
    {
        echo ""
        echo "================================================================"
        echo "Exit code: $build_result; Duration: ${total_duration}s"
        echo "================================================================"
    } >> "$BUILD_LOG"
    exit "$build_result"
}

trap 'print_message "ERROR" "Build interrupted!"; exit 130' INT TERM

main "$@"
