#!/bin/bash

# build.sh - build MicroPython firmware with wifi_pro user C module
# run from the workspace root (/workspaces/Github-Codespace)
# ensures ESP-IDF v5.5.1 is installed, builds mpy-cross, then compiles
# the ESP32-S3+OPI firmware with the custom user module.

set -euxo pipefail

TOP=$(pwd)
IDF_DIR="$TOP/esp-idf"

# install host dependencies that ESP-IDF tools require
# update package lists; some repos may be misconfigured so ignore errors
sudo apt-get update || true
sudo apt-get install -y libusb-1.0-0-dev || true

# clone/prepare ESP-IDF if missing
if [ ! -d "$IDF_DIR" ]; then
    echo "Cloning ESP-IDF v5.5.1 into $IDF_DIR"
    git clone -b v5.5.1 --recursive https://github.com/espressif/esp-idf.git "$IDF_DIR"
fi

cd "$IDF_DIR"

git fetch --tags origin
git checkout v5.5.1
git submodule update --init --recursive

# install the toolchain and python requirements (idempotent)
./install.sh esp32s3
source export.sh

# build the cross compiler used for freezing
cd "$TOP/micropython/mpy-cross"
make -j$(nproc)

# now build the firmware
cd "$TOP/micropython/ports/esp32"

# ensure submodules are present (network drivers, etc.)
make submodules

make BOARD=ESP32_GENERIC_S3 \
     BOARD_VARIANT=SPIRAM_OCT \
     USER_C_MODULES=$TOP/user_c_modules/wifi_pro/micropython.cmake \
     CFLAGS+=-DCONFIG_SPIRAM_MODE_OCT \
     -j$(nproc) V=1

# final binary resides in build-ESP32_GENERIC_S3-SPIRAM_OCT/firmware.bin

echo "Build finished. firmware location:" $(pwd)/build-ESP32_GENERIC_S3-SPIRAM_OCT/firmware.bin
