# B3 virtual machines (Windows VMs on the bases)

Every B3 base (Base2, Base3, Base4, Base5, Base6, Base8) runs four VirtualBox Windows VMs,
`Virtual.<base>A` - `Virtual.<base>D`. This page is the standard for setting them up on a
base installed with this repository (steps 14 VirtualBox, 15 Syncthing, 16 autostart).
First done when moving Virtual.3A-D from Base3 (Windows host) to Base8 (Ubuntu 26.04).

## Hardware of one VM

| Setting | Value |
|---|---|
| OS type | Windows 10 32-bit (`Windows10`, PAE on, long mode off) |
| CPU / RAM | 2 vCPU, 3 GB - 4 VMs x 3 GB on a ~14 GB host is the normal, working load |
| Firmware | EFI |
| Graphics | VBoxSVGA, 64 MB, screen fixed at 1366x768 (see below) |
| Disk | SATA (AHCI, host I/O cache), `<name>.vdi`, marked as SSD (`--nonrotational on`) |
| DVD | empty drive on SATA port 1 |
| Network | Intel PRO/1000 MT (82540EM), bridged to the host LAN interface, new MAC |
| Pointer | USB tablet + USB OHCI (no mouse capture) |
| Audio | HDA with the null driver (host has no sound) |
| Shared folder | `Sync` = host `~/Sync` (Syncthing), auto-mounted as `S:` |
| Autostart | on; first VM delay 0 s, the others 30 s (steps 16) |

`b3/b3-vm-create.sh <name> <disk.vdi> [delay_s]` (as the VM owner) registers a VM with all of
this from an existing disk; the network cable stays unplugged (see Chrome Remote Desktop).

## Moving VMs from another base

1. Shut the VMs down cleanly in Windows on the old base (no hibernation / fast startup) and
   keep them off until the copy is done.
2. Copy only the `.vdi` disks, renamed to the new name, e.g. Base3 `Virtual.3A/Virtual.07.vdi`
   -> Base8 `~/VirtualBox VMs/Virtual.8A/Virtual.8A.vdi` (Base8: `//Base3.local/c` mounted via
   CIFS, resumable `rsync --partial --append-verify`). The old `.vbox` files are not used:
   they hold Windows host paths (shared folder `S:\`, bridged "Realtek PCIe GbE").
   Snapshots folders held only old `.sav` files, no snapshot disks - check before copying.
3. `b3/b3-vm-create.sh` for every VM.
4. `sudo b3/b3-vm-remove-crd.sh <disk.vdi> ...` while the VMs are off.
5. Plug the cable in: `VBoxManage modifyvm <name> --cable-connected1 on`, start the VMs
   (`vbox-autostart start` or the next boot) and register Chrome Remote Desktop again inside.

A 100 Mbit/s switch port limits the copy to ~11 MB/s (4 x 43 GB = ~4.5 h); Syncthing on the
same link slows it further.

## Chrome Remote Desktop inside the VMs

- A copied VM carries the CRD host identity of its original (`C:\ProgramData\Google\Chrome
  Remote Desktop\host.json`, `host_unprivileged.json`). With network on, both would claim the
  same host - so the cable stays unplugged until these two files are gone.
- `b3/b3-vm-remove-crd.sh` deletes them offline (qemu-nbd + ntfs-3g, VM off, refuses an open
  disk). The CRD program stays installed; register the host again inside the VM.
- The Windows host installer `chromeremotedesktophost.msi` is a 32-bit package (MSI template
  `Intel`, PE32 binaries) - fine for the 32-bit guests. Kept on `S:` for installing.
- CRD and the VirtualBox Guest Additions inside the VMs are updated by hand (not by apt).

## Mouse capture

With the default PS/2 mouse VirtualBox captures the pointer; over Chrome Remote Desktop to the
host the capture gets stuck. Release: right Ctrl (host key). Fix: USB tablet
(`--mouse usbtablet --usb-ohci on`, VM powered off) - absolute pointer, no capture.

## Screen always 1366x768

Per VM (extradata, set by `b3-vm-create.sh`):

| Key | Value | Effect |
|---|---|---|
| `GUI/AutoresizeGuest` | `false` | the guest does not follow the VirtualBox window size |
| `GUI/LastGuestSizeHint` | `1366,768` | the window opens at this size |
| `CustomVideoMode1` | `1366x768x32` | mode offered by the virtual graphics |
| `VBoxInternal2/EfiGraphicsResolution` | `1366x768` | same mode at EFI / boot (next cold start) |

Running VM right away: `VBoxManage controlvm <name> setvideomodehint 1366 768 32`. Set
1366x768 once in Windows display settings too; if it still changes, the CRD client inside the
VM resizes the desktop ("Resize desktop to fit" in the CRD side panel).

## Shared folder S:

- After updating the Guest Additions, restart Windows properly (Start -> Restart): the shared
  folder driver is replaced and only loads after a restart. Until then the log shows
  `Failed to attach 'Sync' to 'S:': VERR_NET_PATH_NOT_FOUND` and `VBOXNP: Error opening device`.
- Programs run as administrator do not see `S:` (UAC runs them in a separate logon; the
  Windows Installer service runs as SYSTEM): an installer from `S:` asks for elevation and
  then quits. Fix once per VM: `b3/EnableLinkedConnections.reg` (HKLM ...\Policies\System
  `EnableLinkedConnections`=1) and restart Windows. Start the `.reg` from `\\VBoxSvr\Sync` or a
  local copy, not from `S:` (regedit itself runs as administrator). The UNC path
  `\\VBoxSvr\Sync\...` also works for elevated programs without the registry change.
