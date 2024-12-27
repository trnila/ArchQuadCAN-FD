#!/bin/bash
if [ -z "$1" ]; then
  echo Usage: "$0" /dev/mmcblkX
  exit 1
fi

set -ex
DEV=$1
MNT="mnt"
SSH_KEY="/home/$SUDO_USER/.ssh/id_rsa.pub"

cleanup() {
  umount "$MNT/boot" || true
  umount "$MNT" || true
}

trap cleanup EXIT

(
  echo o # create dos partion table
  echo -e "n\np\n1\n\n+500M" # add primary partion 1
  echo -e "t\nc\n" # partition type W95 FAT32 (LBA)
  echo -e "n\np\n2\n\n\n" # add primary partion 2 with rest of space
  echo w # save table
) | fdisk "$DEV" --noauto-pt --wipe-partitions always

mkfs.fat "$DEV"p1
mkfs.ext4 "$DEV"p2

mkdir -p "$MNT"
mount "$DEV"p2 "$MNT"
mkdir -p "$MNT/boot"
mount "$DEV"p1 "$MNT/boot"

tar -xpf archquadcan-fd.tar -C "$MNT" || true # fails on FAT32 missing permissions functionality

if [ -f "$SSH_KEY" ]; then
  mkdir -p "$MNT/root/.ssh"
  cp "$SSH_KEY" $MNT/root/.ssh/authorized_keys
  chmod -R 600 "$MNT/root/.ssh"
fi

rm "$MNT/.dockerenv"

sync

echo "Image written"
