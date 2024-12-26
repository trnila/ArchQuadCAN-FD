#!/bin/bash
set -ex

ROOTFS_URL=http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz
IMAGE_NAME=archquadcan-fd
BASE_IMAGE_NAME="$IMAGE_NAME"-base
TAR_PATH="$IMAGE_NAME".tar

if [ -z "$(docker images -q "$BASE_IMAGE_NAME")" ]; then
	curl -L "$ROOTFS_URL" | docker import - "$BASE_IMAGE_NAME"
fi

docker build --build-arg FROM="$BASE_IMAGE_NAME" -t "$IMAGE_NAME" .
CONTAINER=$(docker container create "$IMAGE_NAME" true)
docker export "$CONTAINER" -o "$TAR_PATH"
docker rm "$CONTAINER"

echo Built successfuly as "$TAR_PATH"
