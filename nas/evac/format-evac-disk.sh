#!/usr/bin/env bash
# Format one evacuation USB HDD (ticket 01), refusing anything that isn't one.
#
#   sudo ./format-evac-disk.sh <a|b> /dev/disk/by-id/usb-...-part1
#
# a → ext4, label evac-a.   b → NTFS (mkntfs from ntfs3g), label evac-b.
# Only ever formats the given *partition*; the partition table is left alone.
set -euo pipefail

die() { echo "REFUSED: $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "run with sudo"
[[ $# -eq 2 ]] || die "usage: $0 <a|b> /dev/disk/by-id/usb-...-part1"
which=$1 part_link=$2

case $which in
  a) label=evac-a ;;
  b) label=evac-b ;;
  *) die "first argument must be a or b" ;;
esac

# Guard 1: the name must be a stable USB by-id link, never /dev/sdX or /dev/nvme*.
[[ $part_link == /dev/disk/by-id/usb-*-part[0-9]* ]] \
  || die "pass a /dev/disk/by-id/usb-...-partN path, not a /dev/sdX name"
[[ -b $part_link ]] || die "$part_link does not exist (is the drive plugged in?)"

part=$(readlink -f "$part_link")
disk=/dev/$(lsblk -no PKNAME "$part")

# Guard 2: what the kernel says about the parent disk.
tran=$(lsblk -dno TRAN "$disk")
size=$(lsblk -dbno SIZE "$disk")
model=$(lsblk -dno MODEL "$disk" | xargs)
serial=$(lsblk -dno SERIAL "$disk" | xargs)

[[ $tran == usb ]] || die "$disk is on '$tran', not usb"
[[ $disk != /dev/nvme* ]] || die "$disk is an NVMe device"
(( size < 2200000000000 )) || die "$disk is larger than 2.2 TB — not an evacuation disk"

# Guard 3: nothing on this disk may be mounted.
if lsblk -no MOUNTPOINTS "$disk" | grep -q .; then
  die "something on $disk is mounted — unmount it first"
fi

echo
echo "About to ERASE and format:"
echo "  partition : $part  ($part_link)"
echo "  disk      : $disk  $model  serial=$serial  $(lsblk -dno SIZE "$disk")  via $tran"
echo "  current   : $(lsblk -no FSTYPE,LABEL,SIZE "$part" | xargs)"
echo "  new       : $([[ $which == a ]] && echo ext4 || echo NTFS)  label=$label"
echo
echo "Every disk on this machine, for comparison:"
lsblk -o NAME,SIZE,TRAN,FSTYPE,LABEL,MODEL,SERIAL
echo
read -r -p "Type the serial ($serial) to confirm: " answer
[[ $answer == "$serial" ]] || die "serial did not match — nothing was changed"

if [[ $which == a ]]; then
  # no -F: mkfs.ext4 asks once more if it finds an existing filesystem
  mkfs.ext4 -L "$label" -m 0 "$part"
else
  ntfs3g=$(nix build --no-link --print-out-paths "nixpkgs#ntfs3g.out")
  "$ntfs3g/bin/mkntfs" -Q -L "$label" "$part"
fi

echo
echo "Done. $part is now $label:"
lsblk -o NAME,SIZE,TRAN,FSTYPE,LABEL,MODEL,SERIAL "$disk"
