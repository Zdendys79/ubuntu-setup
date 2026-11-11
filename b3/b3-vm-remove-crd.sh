#!/bin/bash
# b3-vm-remove-crd.sh - delete the Chrome Remote Desktop host registration from a powered-off
# Windows VM disk, so a copied VM does not appear as the same CRD host as its original.
#
# Usage: sudo b3/b3-vm-remove-crd.sh <disk.vdi> [<disk.vdi> ...]
# Removes C:\ProgramData\Google\Chrome Remote Desktop\host.json and host_unprivileged.json
# (the CRD program stays installed; register the host again inside the VM). The VM must be
# powered off. Windows must have been shut down cleanly (no hibernation / fast startup),
# otherwise ntfs-3g refuses to write and nothing is changed.
# Needs qemu-utils (qemu-nbd) and ntfs-3g.
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "[ERROR] run with sudo"; exit 1; }
[ $# -gt 0 ] || { echo "usage: $0 <disk.vdi> ..."; exit 2; }
command -v qemu-nbd >/dev/null || apt-get install -y --no-install-recommends qemu-utils
NBD=/dev/nbd0
MNT=$(mktemp -d)
rc=0

cleanup() {
    mountpoint -q "$MNT" && umount "$MNT"
    qemu-nbd --disconnect "$NBD" >/dev/null 2>&1 || true
    rmdir "$MNT" 2>/dev/null || true
}
trap cleanup EXIT
modprobe nbd max_part=16

for disk in "$@"; do
    echo "== $disk"
    if fuser -s "$disk" 2>/dev/null; then
        echo "[ERROR] $disk is open (VM running?) - skipped"; rc=1; continue
    fi
    if ! qemu-nbd --format=vdi --connect="$NBD" "$disk"; then
        echo "[ERROR] cannot attach $disk (VM running?)"; rc=1; continue
    fi
    part=""
    for _ in $(seq 1 10); do  # partition nodes of the nbd device appear with a delay
        udevadm settle
        for p in "$NBD"p*; do
            [ -b "$p" ] && [ "$(blkid -o value -s TYPE "$p" 2>/dev/null)" = ntfs ] && { part=$p; break; }
        done
        [ -n "$part" ] && break
        sleep 1
    done
    if [ -z "$part" ] || ! ntfs-3g "$part" "$MNT"; then
        echo "[ERROR] NTFS partition not writable (unclean Windows shutdown?) - unchanged"; rc=1
    else
        dir="$MNT/ProgramData/Google/Chrome Remote Desktop"
        if [ -f "$dir/host.json" ] || [ -f "$dir/host_unprivileged.json" ]; then
            rm -f "$dir/host.json" "$dir/host_unprivileged.json"
            echo "[OK] CRD host config removed"
        else
            echo "[INFO] no CRD host config"
        fi
        sync
        umount "$MNT"
    fi
    qemu-nbd --disconnect "$NBD" >/dev/null
    sleep 1
done
exit "$rc"
