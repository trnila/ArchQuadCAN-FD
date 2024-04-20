#!/bin/bash
set -ex

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

pacman -Syu --noconfirm --needed \
  wget \
  vim \
  tmux \
  strace \
  htop \
  base-devel \
  git \
  python-pip \
  python-can \
  uboot-tools \
  cmake \
  ninja \
  dtc

# install can-utils
(
  cd /tmp
  wget https://aur.archlinux.org/cgit/aur.git/snapshot/can-utils-git.tar.gz
  tar -xf can-utils-git.tar.gz
  cd can-utils-git
  chown nobody -R .
  runuser -u nobody -- makepkg -f
  pacman --noconfirm -U ./*.pkg.tar.xz
)

# copy configurations into system
rm -f /etc/systemd/network/{en,eth}.network
cp -rv files/* /

# compile Device Tree overlay
dtc -@ -I dts -O dtb archquadcan-fd-overlay.dts > /boot/dtbs/archquadcan-fd-overlay.dtbo

# compile u-boot script boot.txt into boot.scr
(cd /boot && ./mkscr)

# enable ACM serial console over USB
mkdir -p /etc/systemd/system/getty.target.wants/
ln -sf /usr/lib/systemd/system/serial-getty@.service /etc/systemd/system/getty.target.wants/serial-getty@ttyGS0.service

echo "Provision successful"
