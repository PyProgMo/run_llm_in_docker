#!/bin/bash
# setMI50state.sh — power off/on the MI50 (card1) via PCI remove/rescan.
# Usage: sudo ./setMI50state.sh on|off [--force]
#
# Run on the HOST as root. Not for use inside the container.
#
# WHAT THIS DOES NOT PROTECT AGAINST:
#   Vega20 (MI50) has a known amdgpu driver weakness where the device
#   sometimes fails to re-initialize cleanly after a PCI remove/rescan
#   cycle. If that happens, "on" will report failure and you will need
#   to reboot the host to recover the card. No sysfs-level check can
#   fully rule this out ahead of time — this script minimizes avoidable
#   risk (wrong device, busy device, silent failure) but cannot
#   guarantee the ASIC/driver combo always survives a hot-remove.

set -euo pipefail

CARD="card1"
DEVICE_PATH="/sys/class/drm/${CARD}/device"
STATE_DIR="/var/lib/mi50-power"
STATE_FILE="${STATE_DIR}/pci_addr"
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

find_render_node() {
    # Find the /dev/dri/renderDxxx node belonging to this device, if it exists.
    local drm_dir="${DEVICE_PATH}/drm"
    [ -d "$drm_dir" ] || return 0
    for entry in "$drm_dir"/render*; do
        [ -e "$entry" ] && basename "$entry"
    done
}

check_busy() {
    # Refuse to remove a device with open handles unless --force is given.
    local busy=0
    local render_node
    render_node=$(find_render_node || true)

    if [ -e /dev/kfd ]; then
        if fuser /dev/kfd >/dev/null 2>&1; then
            log "WARNING: /dev/kfd has open handles:"
            fuser -v /dev/kfd 2>&1 | sed 's/^/    /'
            busy=1
        fi
    fi

    if [ -n "$render_node" ] && [ -e "/dev/dri/${render_node}" ]; then
        if fuser "/dev/dri/${render_node}" >/dev/null 2>&1; then
            log "WARNING: /dev/dri/${render_node} has open handles:"
            fuser -v "/dev/dri/${render_node}" 2>&1 | sed 's/^/    /'
            busy=1
        fi
    fi

    # Best-effort: flag docker containers with the device mapped in.
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
    if [ ! -e "$DEVICE_PATH" ]; then
        log "no device at ${DEVICE_PATH} — already off, or path/index wrong"
        exit 0
    fi

    local pci_addr
    pci_addr=$(basename "$(readlink -f "$DEVICE_PATH")")
    [[ "$pci_addr" =~ ^[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}\.[0-9a-fA-F]$ ]] \
        || die "resolved PCI address '$pci_addr' doesn't look valid — aborting, not touching it"

    check_busy

    log "saving PCI address ${pci_addr} to ${STATE_FILE}"
    echo "$pci_addr" > "$STATE_FILE"

    log "removing PCI device ${pci_addr}"
    if ! echo 1 > "/sys/bus/pci/devices/${pci_addr}/remove" 2>/tmp/mi50_remove_err; then
        die "remove failed: $(cat /tmp/mi50_remove_err)"
    fi

    sleep 1
    if [ -e "/sys/bus/pci/devices/${pci_addr}" ]; then
        die "device still present after remove — did NOT complete cleanly, check dmesg"
    fi
    log "GPU powered off (removed from PCI bus)."
}

do_on() {
    [ -f "$STATE_FILE" ] || log "no saved PCI address found — rescanning bus generally"
    local pci_addr=""
    [ -f "$STATE_FILE" ] && pci_addr=$(cat "$STATE_FILE")

    log "rescanning PCI bus"
    echo 1 > /sys/bus/pci/rescan

    local timeout=80
    local waited=0
    while [ "$waited" -lt "$timeout" ]; do
        if [ -e "$DEVICE_PATH" ]; then
            log "GPU is back: ${DEVICE_PATH} present."
            if [ -n "$pci_addr" ]; then
                local now_addr
                now_addr=$(basename "$(readlink -f "$DEVICE_PATH")")
                [ "$now_addr" = "$pci_addr" ] || log "NOTE: reappeared at ${now_addr}, previously ${pci_addr}"
            fi
            log "Driver-level reinit (ROCm/KFD contexts, containers) is NOT automatic —"
            log "restart any inference container/process that was using the GPU."
            exit 0
        fi
        sleep 1
        waited=$((waited + 1))
    done

    die "device did not reappear after ${timeout}s — check 'dmesg | tail -50'. If amdgpu logged errors during rebind, a reboot is likely required to recover the card."
}

case "$ACTION" in
    off) do_off ;;
    on)  do_on ;;
    *)   usage ;;
esac
