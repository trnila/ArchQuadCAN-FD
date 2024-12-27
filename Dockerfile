ARG FROM="archquadcan-fd-base"
FROM ${FROM} 

ADD files/etc/pacman.d /etc/pacman.d/
RUN pacman-key --init && pacman-key --populate

# upgrade downloaded image to latest state
RUN --mount=target=/var/cache/pacman/pkg,type=cache,rw=true \
  sed -i '/CheckSpace/d' /etc/pacman.conf \
  && sed -Ei "s/PRESETS=.+/PRESETS=('default')/" /etc/mkinitcpio.d/linux-aarch64.preset \
  && pacman -Syu --noconfirm

RUN --mount=target=/var/cache/pacman/pkg,type=cache,rw=true \
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
    dtc \
    dkms \
    linux-aarch64-headers

# workaround for hanging fakeroot in docker
RUN git clone https://salsa.debian.org/clint/fakeroot.git /tmp/fakeroot \
  && cd /tmp/fakeroot \
  && git checkout upstream/1.34 \
  && ./bootstrap \
  && ./configure --prefix=/usr --libdir=/usr/lib/libfakeroot --disable-static --with-ipc=sysv \
  && make -j$(nproc) \
  && cp faked /usr/bin \
  && cp scripts/fakeroot /usr/bin \
  && cp .libs/libfakeroot.so /usr/lib/libfakeroot/ \
  && rm -rf /tmp/fakeroot

# install can-utils for cansend, candump tools
RUN cd /tmp \
  && curl https://aur.archlinux.org/cgit/aur.git/snapshot/can-utils-git.tar.gz | tar -xzf - \
  && cd can-utils-git \
  && chown nobody -R . \
  && runuser -u nobody -- makepkg -f \
  && pacman --noconfirm -U ./*.pkg.tar.xz \
  && rm -rf /tmp/can-utils-git

# install patched module for driving transceiver standby pin
ADD mcp251xfd-xstby-dkms /tmp/mcp251xfd-xstby-dkms
RUN --mount=target=/cache,type=cache \
  cd /tmp/mcp251xfd-xstby-dkms/ \
  && chown nobody -R . /cache \
  && runuser -u nobody -- env SRCDEST=/cache makepkg \
  && pacman --noconfirm -U ./*.pkg.tar.xz \
  && rm -rf /tmp/mcp251xfd-xstby-dkms

ADD files/ /

# compile Device Tree overlay for the board
ADD archquadcan-fd-overlay.dts /boot/
RUN dtc -@ -I dts -O dtb /boot/archquadcan-fd-overlay.dts > /boot/dtbs/archquadcan-fd-overlay.dtbo \
 # compile u-boot script boot.txt into boot.scr
 && cd /boot \
 && ./mkscr 

# enable ACM serial console over USB
RUN mkdir -p /etc/systemd/system/getty.target.wants/ \
  && ln -sf /usr/lib/systemd/system/serial-getty@.service /etc/systemd/system/getty.target.wants/serial-getty@ttyGS0.service

RUN userdel -r alarm \  
  # allow only ssh key auth and root user
  && sed -Ei 's/#?PermitRootLogin.+/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config \
  && sed -Ei 's/#?PasswordAuthentication.+/PasswordAuthentication no/' /etc/ssh/sshd_config \
  # remove default network configurations
  && rm -f /etc/systemd/network/{en,eth}.network \
  # rpi4 is using mmcblk1
  && sed -i 's/mmcblk0/mmcblk1/g' "/etc/fstab" \
  && rm -f /boot/initramfs-linux-fallback.img
