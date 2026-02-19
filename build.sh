#!/bin/bash
# Build script for ESP WiFi 802.11 TX MicroPython module on ESP32-S3

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BOARD=${1:-ESP32_S3}
TARGET_PORT=${2:-/dev/ttyUSB0}
BAUD=${3:-460800}

echo -e "${GREEN}ESP WiFi 802.11 TX Module - Build Script${NC}"
echo "=========================================="
echo "Board: $BOARD"
echo "Port: $TARGET_PORT"
echo "Baud: $BAUD"
echo ""

# Check if MicroPython source exists
if [ ! -d "micropython" ]; then
    echo -e "${YELLOW}MicroPython source not found. Cloning...${NC}"
    git clone https://github.com/micropython/micropython.git
    cd micropython
else
    echo -e "${GREEN}✓ MicroPython source found${NC}"
    cd micropython
fi

# Check if mpy-cross is built
if [ ! -f "mpy-cross/mpy-cross" ]; then
    echo -e "${YELLOW}Building mpy-cross...${NC}"
    cd mpy-cross
    make
    cd ..
else
    echo -e "${GREEN}✓ mpy-cross already built${NC}"
fi

# Copy module to MicroPython
echo -e "${YELLOW}Copying esp_wifi_tx module...${NC}"
mkdir -p ports/esp32/modules/esp_wifi_tx
if [ -f "../micropython_esp_wifi_tx/esp_wifi_80211_tx.c" ]; then
    cp ../micropython_esp_wifi_tx/* ports/esp32/modules/esp_wifi_tx/
    echo -e "${GREEN}✓ Module copied${NC}"
else
    echo -e "${RED}✗ Module files not found!${NC}"
    exit 1
fi

# Setup ESP-IDF environment
if [ -z "$IDF_PATH" ]; then
    if [ -d "$HOME/esp/esp-idf" ]; then
        echo -e "${YELLOW}Setting IDF_PATH to $HOME/esp/esp-idf${NC}"
        export IDF_PATH="$HOME/esp/esp-idf"
        source "$IDF_PATH/export.sh"
    else
        echo -e "${RED}✗ ESP-IDF not found. Set IDF_PATH environment variable${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ IDF_PATH is set: $IDF_PATH${NC}"
fi

# Navigate to ESP32 port
cd ports/esp32

# Clean previous build
echo -e "${YELLOW}Cleaning previous builds...${NC}"
make clean || true

# Build firmware
echo -e "${YELLOW}Building MicroPython firmware for $BOARD...${NC}"
make BOARD=$BOARD -j$(nproc)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Build successful!${NC}"
    FIRMWARE_FILE="build-${BOARD}/firmware.bin"
    
    if [ ! -f "$FIRMWARE_FILE" ]; then
        echo -e "${RED}✗ Firmware file not found: $FIRMWARE_FILE${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}Firmware ready at: $FIRMWARE_FILE${NC}"
    echo ""
    
    # Ask to flash
    read -p "Flash to device now? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Flashing firmware to $TARGET_PORT...${NC}"
        
        # Check if device is available
        if [ ! -c "$TARGET_PORT" ]; then
            echo -e "${RED}✗ Device not found at $TARGET_PORT${NC}"
            exit 1
        fi
        
        # Flash using esptool.py
        python3 -m esptool \
            -p "$TARGET_PORT" \
            -b $BAUD \
            --before default_reset \
            --after hard_reset \
            --chip esp32s3 \
            write_flash -z \
            --flash_mode dio \
            --flash_freq 80m \
            --flash_size 16MB \
            0x0 "$FIRMWARE_FILE"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Flash successful!${NC}"
            echo ""
            echo -e "${GREEN}Device flashed successfully!${NC}"
            echo ""
            echo "Next steps:"
            echo "1. Connect to the device:"
            echo "   screen $TARGET_PORT $BAUD"
            echo ""
            echo "2. In MicroPython REPL, test the module:"
            echo "   import esp_wifi_tx"
            echo "   print(esp_wifi_tx.WIFI_IF_STA)"
        else
            echo -e "${RED}✗ Flash failed!${NC}"
            exit 1
        fi
    else
        echo "Flash cancelled."
        echo "To flash manually, run:"
        echo ""
        echo "python3 -m esptool -p $TARGET_PORT -b $BAUD --before default_reset --after hard_reset --chip esp32s3 write_flash -z --flash_mode dio --flash_freq 80m --flash_size 16MB 0x0 $FIRMWARE_FILE"
    fi
else
    echo -e "${RED}✗ Build failed!${NC}"
    exit 1
fi
