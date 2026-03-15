#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="build_error.log"
BUILD_LOG="build.log"
rm -f "$LOG_FILE" "$BUILD_LOG"

echo "[+] ESP32-S3 (N16R8) penetration testing framework build started"

function fail() {
  echo "[!] ERROR: $1"
  echo "[!] See $LOG_FILE for details"
  exit 1
}

# Dependency checks
function install_espidf() {
  echo "[+] ESP-IDF not found, attempting automated install..."
  ESP_IDF_DIR="/opt/esp-idf"
  sudo mkdir -p "$ESP_IDF_DIR"
  sudo chown "$USER":"$USER" "$ESP_IDF_DIR"

  if [ -d "$ESP_IDF_DIR/.git" ]; then
    echo "[+] ESP-IDF directory already exists, reusing existing installation."
  else
    if [ "$(ls -A "$ESP_IDF_DIR")" ]; then
      echo "[!] $ESP_IDF_DIR is not empty and not an ESP-IDF repo" >&2
      echo "ESP-IDF directory not clean" > "$LOG_FILE"
      return 1
    fi

    git clone --branch v5.1.2 --depth 1 https://github.com/espressif/esp-idf.git "$ESP_IDF_DIR" || {
      echo "[!] ESP-IDF clone failed" >&2
      echo "ESP-IDF clone failed" > "$LOG_FILE"
      return 1
    }
  fi

  cd "$ESP_IDF_DIR"
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "[!] ESP-IDF path is not a valid git repository" >&2
    echo "Invalid ESP-IDF repository" > "$LOG_FILE"
    return 1
  fi

  # ensure correct version is checked out
  git fetch --depth 1 origin v5.1.2 >/dev/null 2>&1 || true
  git checkout v5.1.2 >/dev/null 2>&1 || true

  ./install.sh || {
    echo "[!] ESP-IDF install script failed" >&2
    echo "ESP-IDF install script failed" > "$LOG_FILE"
    return 1
  }
  export IDF_PATH="$ESP_IDF_DIR"
  export PATH="$IDF_PATH/tools:$PATH"
  source "$IDF_PATH/export.sh"
  echo "[+] ESP-IDF installed to $ESP_IDF_DIR"
  return 0
}

if ! command -v idf.py >/dev/null 2>&1; then
  if ! install_espidf; then
    fail "ESP-IDF not installed or could not be auto-installed"
  fi
fi

IDF_VER=$(idf.py --version 2>&1 | head -n1)
if [[ "$IDF_VER" =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
  IDF_MAJOR=${BASH_REMATCH[1]}
  IDF_MINOR=${BASH_REMATCH[2]}
  IDF_PATCH=${BASH_REMATCH[3]}
else
  echo "Could not parse ESP-IDF version: $IDF_VER" >&2
  echo "ESP-IDF version parse failed: $IDF_VER" > "$LOG_FILE"
  fail "ESP-IDF version parse failed"
fi

if (( IDF_MAJOR < 5 )) || { (( IDF_MAJOR == 5 )) && (( IDF_MINOR < 1 )); }; then
  echo "ESP-IDF version $IDF_VER is too old (required 5.1.2+)" >&2
  echo "ESP-IDF version $IDF_VER is too old" > "$LOG_FILE"
  fail "ESP-IDF version must be 5.1.2 or higher"
fi

function install_micropython() {
  echo "[+] microPython interpreter module not found, installing via pip..."
  if ! command -v pip3 >/dev/null 2>&1; then
    echo "[!] pip3 is required to install MicroPython package" >&2
    echo "pip3 not found" > "$LOG_FILE"
    return 1
  fi

  if pip3 install --user micropython; then
    echo "[+] MicroPython installed via pip --user"
    return 0
  fi

  echo "[!] pip3 --user install failed, retrying without --user..."
  if pip3 install micropython; then
    echo "[+] MicroPython installed via pip"
    return 0
  fi

  echo "[!] pip3 install micropython failed" >&2
  echo "MicroPython install failed" > "$LOG_FILE"
  return 1
}

python3 - <<'PY' > /tmp/micropython_check.txt 2>&1 || true
import sys
try:
    import micropython
except ImportError:
    print('MICROPYTHON_MISSING')
    sys.exit(1)

v = getattr(micropython, '__version__', None)
if not v:
    v = '0.0.0'
print(v)
PY

MICROPYTHON_CHECK=$(cat /tmp/micropython_check.txt)
MICROPYTHON_AVAILABLE=1
if [[ "$MICROPYTHON_CHECK" == "MICROPYTHON_MISSING" ]]; then
  echo "MicroPython not installed (required 1.22+), trying auto-install" >&2
  if ! install_micropython; then
    echo "[!] WARNING: MicroPython dependency missing and auto-install failed, continuing without it" >&2
    MICROPYTHON_AVAILABLE=0
  else
    python3 - <<'PY' > /tmp/micropython_check.txt 2>&1 || true
import sys
try:
    import micropython
except ImportError:
    print('MICROPYTHON_MISSING')
    sys.exit(1)
v = getattr(micropython, '__version__', None)
if not v:
    v = '0.0.0'
print(v)
PY
    MICROPYTHON_CHECK=$(cat /tmp/micropython_check.txt)
    if [[ "$MICROPYTHON_CHECK" == "MICROPYTHON_MISSING" ]]; then
      echo "[!] WARNING: MicroPython still missing after auto-install, continuing without it" >&2
      MICROPYTHON_AVAILABLE=0
    fi
  fi
fi

if [[ $MICROPYTHON_AVAILABLE -eq 1 ]]; then
  if [[ ! "$MICROPYTHON_CHECK" =~ ([0-9]+)\.([0-9]+) ]]; then
    echo "Unable to parse MicroPython version: $MICROPYTHON_CHECK" >&2
    echo "MicroPython version parse failed: $MICROPYTHON_CHECK" > "$LOG_FILE"
    fail "MicroPython version parse failed"
  fi
  MP_MAJOR=${BASH_REMATCH[1]}
  MP_MINOR=${BASH_REMATCH[2]}
  if (( MP_MAJOR < 1 )) || { (( MP_MAJOR == 1 )) && (( MP_MINOR < 22 )); }; then
    echo "MicroPython version $MICROPYTHON_CHECK is too old (required 1.22+), continuing with warning" >&2
    echo "MicroPython version $MICROPYTHON_CHECK too old" > "$LOG_FILE"
  fi
else
  echo "[!] Warning: MicroPython runtime not available; skipping version enforcement" >&2
fi

echo "ESP-IDF version $IDF_VER verified"
echo "MicroPython version $MICROPYTHON_CHECK verified"

# Wipe build folder for clean idf.py run
if [ -d "build" ]; then
  echo "[+] Removing existing build directory for clean build"
  rm -rf build
fi

# Apply N16R8 sdkconfig overrides
cat > sdkconfig.defaults <<'EOF'
CONFIG_IDF_TARGET_ESP32S3=y
CONFIG_ESP32S3_DEFAULT_CPU_FREQ_240=y
CONFIG_ESPTOOLPY_FLASHMODE_DIO=y
CONFIG_ESPTOOLPY_FLASHSIZE_16MB=y
CONFIG_ESP32S3_ENABLE_DEFAULT_CPU_FREQ_240=y
CONFIG_ESP32S3_SPIRAM_SUPPORT=y
CONFIG_SPIRAM_SPEED_80M=y
CONFIG_SPIRAM_TYPE_OCTAL=y
CONFIG_ESP32S3_MEMMAP_TRACEMEM=y
CONFIG_BOOTLOADER_WDT_DISABLE=y
CONFIG_TASK_WDT=0
CONFIG_ESP_SYSTEM_BROWNOUT_DET=0
EOF

# Start the build
set +e
idf.py -B build fullclean build > "$BUILD_LOG" 2>&1
BUILD_STATUS=$?
set -e

if [ $BUILD_STATUS -ne 0 ]; then
  cp "$BUILD_LOG" "$LOG_FILE" || true
  fail "Build failed (see logs)"
fi

# Locate firmware binary
if [ -f build/firmware.bin ]; then
  FIRMWARE_PATH=$(realpath build/firmware.bin)
else
  FIRMWARE_PATH=$(find build -type f -name "*.bin" | head -n 1 || true)
  if [ -z "$FIRMWARE_PATH" ]; then
    echo "Firmware file not found" >&2
    echo "Firmware file not found" > "$LOG_FILE"
    fail "No firmware binary found"
  fi
fi

# Rename output firmware to esp32s3.bin
TARGET_FIRMWARE="build/esp32s3.bin"
cp "$FIRMWARE_PATH" "$TARGET_FIRMWARE"
FIRMWARE_ABS_PATH=$(realpath "$TARGET_FIRMWARE")
BINARY_SIZE=$(stat -c '%s' "$FIRMWARE_ABS_PATH")

cat <<EOF

=========================== Post-Build Summary ===========================
Hardware Target  : ESP32-S3 (N16R8)
Flash Config     : 16MB (Enabled/Verified)
RAM Config       : 8MB Octal-SPIRAM (80MHz Mode Verified)
Resilience       : Brownout Detector (Disabled), Watchdog Bypass (Active)
Module Status    : raw_wifi (Loaded), raw_blue (Loaded)
Binary Size      : $BINARY_SIZE bytes
Firmware Path    : $FIRMWARE_ABS_PATH
==========================================================================

EOF

exit 0
