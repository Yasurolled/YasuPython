#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="build_error.log"
BUILD_LOG="build.log"
rm -f "$LOG_FILE" "$BUILD_LOG"

echo "[+] Architect Build System: ESP32-S3 (N16R8) Framework"

# N16R8 ayarlarını oluştur
cat > sdkconfig.defaults <<'CONF'
CONFIG_IDF_TARGET_ESP32S3=y
CONFIG_ESP32S3_DEFAULT_CPU_FREQ_240=y
CONFIG_ESPTOOLPY_FLASHMODE_DIO=y
CONFIG_ESPTOOLPY_FLASHSIZE_16MB=y
CONFIG_ESP32S3_SPIRAM_SUPPORT=y
CONFIG_SPIRAM_SPEED_80M=y
CONFIG_SPIRAM_TYPE_OCTAL=y
CONFIG_BOOTLOADER_WDT_DISABLE=y
CONFIG_TASK_WDT=0
CONFIG_ESP_SYSTEM_BROWNOUT_DET=0
CONF

echo "[+] Starting clean build..."
# idf.py artık path üzerinde hazır olacak
idf.py fullclean
idf.py build > "$BUILD_LOG" 2>&1 || {
    cp "$BUILD_LOG" "$LOG_FILE"
    echo "[!] Build failed! Check build_error.log for details."
    exit 1
}

# Sonuçları topla
FIRMWARE_BIN=$(find build -maxdepth 1 -name "*.bin" | head -n 1)
if [ -n "$FIRMWARE_BIN" ]; then
    cp "$FIRMWARE_BIN" build/esp32s3.bin
    echo "==========================================="
    echo "  BUILD SUCCESSFUL: esp32s3.bin created"
    echo "==========================================="
else
    echo "[!] No binary found after build."
    exit 1
fi
