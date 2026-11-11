#!/bin/bash
# b3-vm-create.sh - register one B3 Windows VM in VirtualBox from an existing .vdi disk.
#
# Usage: b3/b3-vm-create.sh <name> <disk.vdi> [delay_s]     (as the VM owner, not root)
#   name     e.g. Virtual.8A; the disk should already be <basefolder>/<name>/<name>.vdi
#   delay_s  autostart delay (default 30; 0 for the first VM of the host)
# Env: BRIDGE_NIC (default: interface of the default route), SYNC_DIR (default ~/Sync).
#
# B3 standard (docs/b3-virtual-machines.md): Windows 10 32-bit, 2 vCPU, 3 GB RAM, EFI,
# VBoxSVGA 64 MB, screen fixed at 1366x768, USB tablet (no mouse capture), SATA disk as SSD,
# Intel PRO/1000 bridged with a new MAC, NETWORK CABLE UNPLUGGED (plug in after the Chrome
# Remote Desktop host config inside the guest is removed: b3/b3-vm-remove-crd.sh), shared
# folder Sync = ~/Sync as S:, autostart with the host (step 16). Idempotent.
set -euo pipefail

name=${1:?usage: $0 <name> <disk.vdi> [delay_s]}
disk=$(readlink -f "${2:?usage: $0 <name> <disk.vdi> [delay_s]}")
delay=${3:-30}
NIC=${BRIDGE_NIC:-$(ip route show default | awk '{ print $5; exit }')}
SYNC_DIR=${SYNC_DIR:-$HOME/Sync}
base=$(dirname "$(dirname "$disk")")

[ "$(id -u)" -ne 0 ] || { echo "[ERROR] run as the VM owner, not root"; exit 1; }
[ -f "$disk" ] || { echo "[ERROR] disk $disk not found"; exit 1; }
[ -f "$disk.copying" ] && { echo "[ERROR] $disk is still being copied"; exit 1; }
[ -n "$NIC" ] || { echo "[ERROR] no network interface for bridging (set BRIDGE_NIC)"; exit 1; }
if VBoxManage list vms | grep -q "^\"$name\" "; then
    echo "[INFO] $name already registered"
    exit 0
fi

VBoxManage createvm --name "$name" --ostype Windows10 --basefolder "$base" --register
VBoxManage modifyvm "$name" --cpus 2 --memory 3072 --firmware efi --x86-pae on --x86-long-mode off \
    --ioapic on --large-pages on --rtc-use-utc on --graphicscontroller vboxsvga --vram 64 \
    --mouse usbtablet --usb-ohci on \
    --nic1 bridged --bridge-adapter1 "$NIC" --nic-type1 82540EM --mac-address1 auto --cable-connected1 off \
    --audio-driver null --audio-controller hda --audio-enabled on --audio-out on \
    --boot1 disk --boot2 none --boot3 none --boot4 none \
    --autostart-enabled on --autostart-delay "$delay"
VBoxManage storagectl "$name" --name SATA --add sata --controller IntelAhci --portcount 2 \
    --hostiocache on --bootable on
VBoxManage storageattach "$name" --storagectl SATA --port 0 --device 0 --type hdd \
    --medium "$disk" --nonrotational on
VBoxManage storageattach "$name" --storagectl SATA --port 1 --device 0 --type dvddrive --medium emptydrive
# Fixed screen 1366x768: no resizing to the VirtualBox window, same mode for EFI and Windows.
VBoxManage setextradata "$name" GUI/AutoresizeGuest false
VBoxManage setextradata "$name" GUI/LastGuestSizeHint 1366,768
VBoxManage setextradata "$name" CustomVideoMode1 1366x768x32
VBoxManage setextradata "$name" VBoxInternal2/EfiGraphicsResolution 1366x768
VBoxManage sharedfolder add "$name" --name Sync --hostpath "$SYNC_DIR" --automount --auto-mount-point S:

echo "[OK] $name registered ($(VBoxManage showvminfo "$name" --machinereadable | grep -E '^macaddress1='), cable unplugged)."
echo "     After b3/b3-vm-remove-crd.sh: VBoxManage modifyvm $name --cable-connected1 on"
