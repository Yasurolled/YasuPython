#!/bin/bash
# YasuPython - Full Auto Build Script with Bypass
set -e

# 1. Install System Dependencies
sudo apt-get update
sudo apt-get install -y git wget flex bison gperf python3 python3-pip python3-setuptools cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0

# 2. Setup ESP-IDF (v5.0.2 Stable)
if [ ! -d "esp-idf" ]; then
    git clone --recursive -b v5.0.2 https://github.com/espressif/esp-idf.git
    cd esp-idf
    ./install.sh esp32s3
    cd ..
fi

# Source the environment
source esp-idf/export.sh

# 3. FORCE Fix for pkg_resources and BYPASS check
# We install it inside the active IDF virtual env
pip install --upgrade pip setuptools
export IDF_SKIP_CHECK=1

# 4. Setup MicroPython
if [ ! -d "micropython" ]; then
    git clone --recursive https://github.com/micropython/micropython.git
    cd micropython
    make -C mpy-cross
    cd ..
fi

# 5. Inject Octal RAM (N16R8) Config
BOARD_DIR="micropython/ports/esp32/boards/ESP32_GENERIC_S3"
mkdir -p $BOARD_DIR
cat > "$BOARD_DIR/sdkconfig.board" <<EOF
CONFIG_SPIRAM_MODE_OCT=y
CONFIG_SPIRAM_TYPE_ESP32S3=y
CONFIG_SPIRAM_SPEED_80M=y
CONFIG_ESPTOOLPY_FLASHMODE_OPI=y
CONFIG_ESPTOOLPY_FLASHSIZE_16MB=y
CONFIG_SPIRAM_FETCH_INSTRUCTIONS=y
CONFIG_SPIRAM_RODATA=y
EOF

# 6. Build Process
cd micropython/ports/esp32
# Re-export just to be safe before make
source ../../../esp-idf/export.sh
export IDF_SKIP_CHECK=1

make BOARD=ESP32_GENERIC_S3 BOARD_VARIANT=SPIRAM_OCT USER_C_MODULES=../../../user_c_modules/wifi_pro -j$(nproc)

echo "FIRMWARE READY: micropython/ports/esp32/build-ESP32_GENERIC_S3-SPIRAM_OCT/firmware.bin"
