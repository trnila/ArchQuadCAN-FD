#!/bin/bash
set -ex

ROOTFS_URL=http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz
ROOTFS_FILE=${ROOTFS_URL##*/}
ROOTFS_PATH=$(realpath rootfs)
DOWNLOAD_PATH=downloads

unmount_rootfs() {
  mount | grep "$ROOTFS_PATH" | awk '{print $3}' | while read -r mnt; do
    sudo umount "$mnt";
  done
}
trap "set -ex; unmount_rootfs; set -ex" EXIT
unmount_rootfs

mkdir -p "$DOWNLOAD_PATH"

if [ ! -f "$DOWNLOAD_PATH/$ROOTFS_FILE" ]; then
  wget "$ROOTFS_URL" -O "$DOWNLOAD_PATH/$ROOTFS_FILE.part"
  mv "$DOWNLOAD_PATH/$ROOTFS_FILE.part" "$DOWNLOAD_PATH/$ROOTFS_FILE"
fi

sudo rm -rf "$ROOTFS_PATH"
mkdir "$ROOTFS_PATH"
sudo bsdtar -xpf "$DOWNLOAD_PATH/$ROOTFS_FILE" -C "$ROOTFS_PATH"

# cache pacman packages
mkdir -p "$DOWNLOAD_PATH/pkg"
sudo mount --bind "$DOWNLOAD_PATH/pkg" "$ROOTFS_PATH/var/cache/pacman/pkg"

sudo arch-chroot "$ROOTFS_PATH" bash << EOF
    set -ex
    sed -i '/CheckSpace/d' /etc/pacman.conf
    pacman-key --init
    pacman-key --populate

    # delete unused user
    userdel -r alarm || true
    groupdel alarm || true

    # allow only ssh key auth and root user
    sed -Ei 's/#?PermitRootLogin.+/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    sed -Ei 's/#?PasswordAuthentication.+/PasswordAuthentication no/' /etc/ssh/sshd_config

    echo archquadcan-fd > /etc/hostname

    # rpi4 is using mmcblk1
    sed -i 's/mmcblk0/mmcblk1/g' "/etc/fstab"

    # disable uneeded fallback initramfs
    sed -Ei "s/PRESETS=.+/PRESETS=('default')/" /etc/mkinitcpio.d/linux-aarch64.preset
    rm -f /boot/initramfs-linux-fallback.img
EOF

sudo mount -o ro --bind . "$ROOTFS_PATH/mnt"
sudo arch-chroot "$ROOTFS_PATH" bash /mnt/provision.sh

# cleanup
unmount_rootfs
sudo rm -f "$ROOTFS_PATH/root/.bash_history"

sudo tar -cf archquadcan-fd.tar -C rootfs/ .

echo Built successfuly
