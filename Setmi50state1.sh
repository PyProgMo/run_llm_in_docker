#!/bin/bash
# setMI50state.sh — power off/on the MI50 (Vega20) via PCI remove/rescan.
# Usage: sudo ./setMI50state.sh on|off [--force]
#
# Run on the HOST as root. Not for use inside the container.
#
# v2: keyed off the PCI address instead of /sys/class/drm/card1. The DRM
# minor number (card0/card1/...) is NOT guaranteed to be reused after a
# remove/re-add — the device can rebind successfully under a different
# card number, which would make a card1-only check report false failure.
# The PCI address is the stable identity across rebinds.
#
# WHAT THIS DOES NOT PROTECT AGAINST:
#   Vega20 (MI50) has a known amdgpu driver weakness where the device
#   sometimes fails to re-initialize cleanly after a PCI remove/rescan
#   cycle (see gnif/vendor-reset project). If that happens, "on" will
#   report failure and you will need to reboot the host to recover the
#   card. No sysfs-level check can fully rule this out ahead of time.

set -euo pipefail

PCI_ADDR_DEFAULT="0000:0b:00.0"   # fallback if no state file yet
STATE_DIR="/var/lib/mi50-power"
STATE_FILE="${STATE_DIR}/pci_addr"
RENDER_NODE_FILE="${STATE_DIR}/render_node"
FORCE=0

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*"; }
die() { log "ERROR: $*"; exit 1; }

usage() {
    echo "Usage: $0 on|off [--force]"
    exit 1
}

[ "$EUID" -eq 0 ] || die "must run as root"

[ $# -ge 1 ] || usage
ACTION="$1"
shift || true
for arg in "$@"; do
    [ "$arg" = "--force" ] && FORCE=1
done

mkdir -p "$STATE_DIR"

PCI_ADDR="$PCI_ADDR_DEFAULT"
[ -f "$STATE_FILE" ] && PCI_ADDR=$(cat "$STATE_FILE")
PCI_SYS_PATH="/sys/bus/pci/devices/${PCI_ADDR}"

find_current_card() {
    # Find which /sys/class/drm/cardN (if any) currently maps to $PCI_ADDR.
    # Stable across rebinds — do not assume card1.
    local dev
    for dev in /sys/class/drm/card*/device; do
        [ -e "$dev" ] || continue
        if [ "$(basename "$(readlink -f "$dev")")" = "$PCI_ADDR" ]; then
            basename "$(dirname "$dev")"
            return 0
        fi
    done
    return 1
}

is_driver_bound() {
    # True if the amdgpu driver is currently bound to this PCI address.
    [ -e "${PCI_SYS_PATH}/driver" ] || return 1
    [ "$(basename "$(readlink -f "${PCI_SYS_PATH}/driver")")" = "amdgpu" ]
}

find_render_node() {
    local card="$1"
    local drm_dir="/sys/class/drm/${card}/device/drm"
    [ -d "$drm_dir" ] || return 0
    for entry in "$drm_dir"/render*; do
        [ -e "$entry" ] && basename "$entry"
    done
}

check_busy() {
    local busy=0
    local card
    card=$(find_current_card || true)

    if [ -n "$card" ]; then
        local render_node
        render_node=$(find_render_node "$card" || true)
        if [ -e /dev/kfd ] && fuser /dev/kfd >/dev/null 2>&1; then
            log "WARNING: /dev/kfd has open handles:"
            fuser -v /dev/kfd 2>&1 | sed 's/^/    /'
            busy=1
        fi
        if [ -n "$render_node" ] && [ -e "/dev/dri/${render_node}" ] \
           && fuser "/dev/dri/${render_node}" >/dev/null 2>&1; then
            log "WARNING: /dev/dri/${render_node} has open handles:"
            fuser -v "/dev/dri/${render_node}" 2>&1 | sed 's/^/    /'
            busy=1
        fi
    fi

    if command -v docker >/dev/null 2>&1; then
        local containers
        containers=$(docker ps -q 2>/dev/null || true)
        for c in $containers; do
            if docker inspect "$c" 2>/dev/null | grep -qE '/dev/kfd|/dev/dri'; then
                log "WARNING: container $(docker inspect -f '{{.Name}}' "$c") has GPU devices mapped and is running"
                busy=1
            fi
        done
    fi

    if [ "$busy" -eq 1 ]; then
        if [ "$FORCE" -eq 1 ]; then
            log "Busy, but --force given — proceeding anyway. This can crash the process holding the GPU."
        else
            die "device is in use — stop the process/container first, or re-run with --force"
        fi
    fi
}

do_off() {
    if [ ! -e "$PCI_SYS_PATH" ]; then
        log "no device at ${PCI_SYS_PATH} — already off"
        exit 0
    fi

    check_busy

    log "saving PCI address ${PCI_ADDR} to ${STATE_FILE}"
    echo "$PCI_ADDR" > "$STATE_FILE"

    log "removing PCI device ${PCI_ADDR}"
    if ! echo 1 > "${PCI_SYS_PATH}/remove" 2>/tmp/mi50_remove_err; then
        die "remove failed: $(cat /tmp/mi50_remove_err)"
    fi

    sleep 1
    if [ -e "$PCI_SYS_PATH" ]; then
        die "device still present after remove — did NOT complete cleanly, check dmesg"
    fi
    log "GPU powered off (removed from PCI bus)."
}

do_on() {
    log "rescanning PCI bus"
    echo 1 > /sys/bus/pci/rescan

    local timeout=30
    local waited=0
    while [ "$waited" -lt "$timeout" ]; do
        if [ -e "$PCI_SYS_PATH" ] && is_driver_bound; then
            local card render_node
            card=$(find_current_card || echo "unknown")
            render_node=$(find_render_node "$card" || true)
            log "GPU is back: ${PCI_ADDR} bound to amdgpu, DRM node = ${card}."
            if [ -n "$render_node" ]; then
                echo "/dev/dri/${render_node}" > "$RENDER_NODE_FILE"
                log "Render node: /dev/dri/${render_node} (saved to ${RENDER_NODE_FILE})"
            else
                log "WARNING: could not resolve a render node for ${card}"
            fi
            log "Driver-level reinit (ROCm/KFD contexts, containers) is NOT automatic —"
            log "restart any inference container/process that was using the GPU."
            exit 0
        fi
        sleep 1
        waited=$((waited + 1))
    done

    if [ -e "$PCI_SYS_PATH" ] && ! is_driver_bound; then
        die "PCI device ${PCI_ADDR} is present but no driver bound after ${timeout}s — check 'dmesg | tail -50'."
    fi
    die "device did not reappear after ${timeout}s — check 'dmesg | tail -50'. If amdgpu logged errors during rebind, a reboot is likely required to recover the card."
}

case "$ACTION" in
    off) do_off ;;
    on)  do_on ;;
    *)   usage ;;
esac
