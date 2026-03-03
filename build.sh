#!/bin/bash
# YasuPython - Dizin içi Otomatik Derleme Scripti (N16R8 Fix)
set -euxo pipefail

# Çalışılan ana dizini belirle
TOP=$(pwd)
IDF_DIR="$TOP/esp-idf"
MPY_DIR="$TOP/micropython"

# 1. Bağımlılıklar (Codespaces için gerekli)
sudo apt-get update || true
sudo apt-get install -y libusb-1.0-0-dev cmake ninja-build python3-pip git build-essential || true

# 2. ESP-IDF Kurulumu (Eğer dizinde yoksa çeker)
if [ ! -d "$IDF_DIR" ]; then
    echo "[!] ESP-IDF bulunamadı, indiriliyor..."
    git clone -b v5.5.1 --recursive https://github.com/espressif/esp-idf.git "$IDF_DIR"
fi

cd "$IDF_DIR"
./install.sh esp32s3
source export.sh

# 3. MicroPython Kaynak Kodu Kontrolü (Aynı dizinde arar)
cd "$TOP"
if [ ! -d "$MPY_DIR" ]; then
    echo "[!] MicroPython klasörü bulunamadı! Lütfen git clone ile çekin veya scriptin çekmesine izin verin."
    git clone https://github.com/micropython/micropython.git "$MPY_DIR"
    cd "$MPY_DIR"
    git submodule update --init
else
    echo "[+] MicroPython dizini doğrulandı: $MPY_DIR"
fi

# 4. Cross Compiler (mpy-cross) Derleme
cd "$MPY_DIR/mpy-cross"
make -j$(nproc)

# 5. ESP32 Portu ve Modül Enjeksiyonu
cd "$MPY_DIR/ports/esp32"
make submodules
rm -rf build-ESP32_GENERIC_S3-SPIRAM_OCT

# 6. Derleme Komutu (8MB Octal RAM & wifi_pro Modülü)
# USER_C_MODULES artık senin ana dizinindeki user_c_modules'e bakar
make BOARD=ESP32_GENERIC_S3 \
     BOARD_VARIANT=SPIRAM_OCT \
     USER_C_MODULES="$TOP/user_c_modules/wifi_pro" \
     -j$(nproc)

echo "-------------------------------------------------------"
echo "İŞLEM TAMAM YASU!"
echo "Firmware Konumu: $MPY_DIR/ports/esp32/build-ESP32_GENERIC_S3-SPIRAM_OCT/firmware.bin"
echo "-------------------------------------------------------"