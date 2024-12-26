# ArchQuadCAN-FD

ArchlinuxARM on Raspberry Pi [QuadCAN-FD Hat](https://github.com/Bytewerk/QuadCAN-FD) with 4x CAN-FD interfaces.

<img src="archquadcan-fd.webp" height=400>

| **iface** | **SPI** | **CS** | **IRQ** |
|-----------|---------|--------|---------|
| qcan0     | spi0    | GPIO7  | GPIO4   |
| qcan1     | spi0    | GPIO8  | GPIO2   |
| qcan2     | spi1    | GPIO18 | GPIO13  |
| qcan3     | spi1    | GPIO17 | GPIO6   |


## Build and deploy ArchQuadCAN-FD image on Raspberry Pi
Build and deploy image with following steps:
1. (Optional) Run `docker run --rm --privileged multiarch/qemu-user-static --reset -p yes` if you are not having `qemu-user-static`
2. run `./build.sh` to download and build configured image
3. insert SD card to computer
4. run `sudo ./write_sdcard.sh /dev/mmcblkX`, this step will also copy `~/.ssh/id_rsa.pub` to the image for ssh key-authentication
5. insert SD card to Raspberry Pi and power it on
6. connect via `ssh root@archquadcan-fd.local`

Alternatively you can connect USB to your computer and access Raspberry Pi via `g_cdc`:
1. CDC ethernet via link-local IPv6 and DNS-SD
   ```
   $ ssh root@archquadcan-fd.local
   ```
2. ACM serial link
   ```
   $ minicom -D /dev/ttyACM0 -b 115200
   ```
