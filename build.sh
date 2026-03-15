#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="build_error.log"
BUILD_LOG="build.log"
rm -f "$LOG_FILE" "$BUILD_LOG"

echo "[+] Architect Build System: ESP32-S3 (N16R8) Framework"

# Pip bariyerini kırmak için gerekli ortam değişkeni
export PIP_BREAK_SYSTEM_PACKAGES=1

# GitHub Actions ortamındaki ESP-IDF'i aktif et
if [ -d "/opt/esp-idf" ]; then
    source /opt/esp-idf/export.sh
else
    echo "[!] ESP-IDF not found in /opt/esp-idf."
    exit 1
fi

# N16R8 (16MB Flash / 8MB PSRAM) için sdkconfig ayarlarını oluştur
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
# Önceki artıkları temizle ve derlemeyi başlat
idf.py fullclean
idf.py build > "$BUILD_LOG" 2>&1 || {
    cp "$BUILD_LOG" "$LOG_FILE"
    echo "[!] Build failed! Check build_error.log for details."
    exit 1
}

# Oluşan firmware dosyasını isimlendir ve özet çıkar
FIRMWARE_BIN=$(find build -maxdepth 1 -name "*.bin" | head -n 1)
if [ -n "$FIRMWARE_BIN" ]; then
    cp "$FIRMWARE_BIN" build/esp32s3.bin
    echo "==========================================="
    echo "  BUILD SUCCESSFUL: esp32s3.bin created"
    echo "  Size: $(stat -c '%s' build/esp32s3.bin) bytes"
    echo "==========================================="
else
    echo "[!] No binary found after build."
    exit 1
fi

exit 0
