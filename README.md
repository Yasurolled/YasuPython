# MicroPython ESP32-S3 Custom Firmware with WiFi Pro Module

This project builds a custom MicroPython firmware for the **ESP32-S3** board (N16R8 with Octal-SPIRAM) with a custom C module called `wifi_pro` that provides advanced WiFi control capabilities.

## Features

The `wifi_pro` module exposes the following functions:

- **`wifi_pro.set_tx_power(level)`** – Set WiFi transmit power (adjust TX power level)
- **`wifi_pro.send_raw(packet)`** – Send raw IEEE 802.11 frames directly
- **`wifi_pro.set_promiscuous(state)`** – Enable/disable promiscuous mode for packet sniffing

## Project Structure

```
.
├── build.sh                           # Build script (installs dependencies, builds firmware)
├── README.md                          # This file
├── user_c_modules/
│   └── wifi_pro/
│       ├── wifi_pro.c                 # Core module implementation
│       ├── micropython.mk             # Makefile configuration for module
│       └── micropython.cmake          # CMake configuration for module (IDF integration)
├── micropython/                       # MicroPython source (v1.22+)
└── esp-idf/                           # ESP-IDF v5.5.1
```

## Prerequisites

- Linux/macOS environment (or WSL2 on Windows)
- Python 3.8+
- `git` installed
- ~2GB disk space (for ESP-IDF and build artifacts)

## Building the Firmware

### Quick Build

```bash
./build.sh
```

This script will:
1. Install the ESP-IDF toolchain (xtensa-esp32s3 compiler)
2. Install mpy-cross (for frozen modules)
3. Configure the build environment (`TOP` and `USER_C_MODULES` variables)
4. Run `make` to build the firmware

### Build Output

On success, you'll see:

```
Build finished. firmware location: /workspaces/Github-Codespace/micropython/ports/esp32/build-ESP32_GENERIC_S3-SPIRAM_OCT/firmware.bin
```

The following files are generated:
- **`firmware.bin`** – Complete firmware image (includes bootloader, partition table, and MicroPython)
- **`micropython.bin`** – Application binary only
- **`bootloader.bin`** – Second-stage bootloader
- **`partition-table.bin`** – Flash partition layout

## Flashing the Firmware

### Using esptool.py

```bash
python -m esptool --chip esp32s3 -b 460800 --before default_reset --after hard_reset \
  write_flash 0x0 \
  micropython/ports/esp32/build-ESP32_GENERIC_S3-SPIRAM_OCT/firmware.bin
```

Or with automatic port detection:

```bash
python -m esptool --chip esp32s3 -b 460800 --before default_reset --after hard_reset \
  write_flash 0x0 \
  micropython/ports/esp32/build-ESP32_GENERIC_S3-SPIRAM_OCT/firmware.bin
```

### Using IDF Tools

From within the MicroPython ESP32 port directory:

```bash
cd micropython/ports/esp32
idf.py -p /dev/ttyUSB0 flash
```

(Replace `/dev/ttyUSB0` with your board's serial port)

## Using the wifi_pro Module

Once flashed and booted, connect to the board's REPL:

```python
import wifi_pro

# Set TX power to 20 dBm
wifi_pro.set_tx_power(20)

# Send a raw IEEE 802.11 frame
raw_frame = b"\x80\x00\x00\x00\xff\xff\xff\xff\xff\xff\x00\x11\x22\x33\x44\x55"
wifi_pro.send_raw(raw_frame)

# Enable promiscuous mode (packet sniffing)
wifi_pro.set_promiscuous(True)

# Process packets from the WiFi driver...

# Disable promiscuous mode
wifi_pro.set_promiscuous(False)
```

## Module Implementation Details

### Source Code

The `wifi_pro` module is implemented in C using the MicroPython module API:

- **File:** `user_c_modules/wifi_pro/wifi_pro.c`
- **Includes:** `py/obj.h`, `py/runtime.h`, `esp_wifi.h`
- **Registration:** Uses `MP_REGISTER_MODULE` macro for module discovery

### Build Integration

- **Makefile:** `user_c_modules/wifi_pro/micropython.mk` – declares module source and compiler flags
- **CMake:** `user_c_modules/wifi_pro/micropython.cmake` – integrates with ESP-IDF build as an INTERFACE library
- **Build System:** Automatic discovery via `USER_C_MODULES` environment variable

## Customization

### Adding New Functions to wifi_pro

1. Edit `user_c_modules/wifi_pro/wifi_pro.c`
2. Add C function and MicroPython wrapper using macros like `MP_DEFINE_CONST_FUN_OBJ_N`
3. Add the function to the module's globals table
4. Run `./build.sh` to rebuild

Example:

```c
static mp_obj_t wifi_pro_custom_function(mp_obj_t arg) {
    // Your code here
    return mp_const_none;
}
static MP_DEFINE_CONST_FUN_OBJ_1(wifi_pro_custom_function_obj, wifi_pro_custom_function);

// Add to wifi_pro_module_globals_table:
{ MP_ROM_QSTR(MP_QSTR_custom_function), MP_ROM_PTR(&wifi_pro_custom_function_obj) },
```

### Adjusting Board Configuration

To use a different ESP32-S3 board variant:

1. Edit `build.sh` line 45 and change the board name:
   ```bash
   BOARD_NAME="ESP32_GENERIC_S3"  # or other variants
   ```
2. Rebuild

Available boards are in `micropython/ports/esp32/boards/`

## Troubleshooting

### Build Fails: "QSTR not updated"

This happens during the first build. It's expected. Simply re-run `./build.sh` to complete.

### Build Fails: "Missing header files"

Ensure `include/` paths in `user_c_modules/wifi_pro/micropython.mk` are correct:

```makefile
CFLAGS += -I$(TOP)/user_c_modules/wifi_pro
CFLAGS += -I$(TOP)
```

### Flashing Fails: "Device not found"

1. Check serial connection: `ls /dev/tty*`
2. Adjust baud rate or port in esptool command
3. Hold BOOT button while plugging in if device doesn't enumerate

## References

- [MicroPython Documentation](https://docs.micropython.org/)
- [MicroPython C API](https://docs.micropython.org/en/latest/reference/cextensions.html)
- [ESP32-S3 Datasheet](https://www.espressif.com/sites/default/files/documentation/esp32-s3_datasheet_en.pdf)
- [ESP-IDF Programming Guide](https://docs.espressif.com/projects/esp-idf/en/v5.5.1/)
- [ESP WiFi API Reference](https://docs.espressif.com/projects/esp-idf/en/v5.5.1/esp32s3/api-reference/network/esp_wifi.html)

## License

This project builds on:
- **MicroPython** – MIT License
- **ESP-IDF** – Apache License 2.0

Custom code (build script, module implementation) – Make your own license choice.

## Notes

- The firmware is built for **Octal-SPIRAM** configuration. For different RAM configurations, adjust the board name.
- The build uses `std=gnu17` and optimization level `-O2` by default.
- Firmware size is approximately **1.7 MB** (varies with module additions).
- Build artifacts are stored in `/tmp/` and the build directory. Use `/mnt/` if `/tmp` runs out of space.

## Quick Start Summary

```bash
# 1. Clone or navigate to repo
cd /workspaces/Github-Codespace

# 2. Build firmware
./build.sh

# 3. Flash to board (adjust port as needed)
python -m esptool --chip esp32s3 -b 460800 --before default_reset --after hard_reset \
  write_flash 0x0 micropython/ports/esp32/build-ESP32_GENERIC_S3-SPIRAM_OCT/firmware.bin

# 4. Connect to REPL and test
python -m serial.tools.miniterm /dev/ttyUSB0 115200

# 5. Import and use the module
import wifi_pro
wifi_pro.set_promiscuous(True)
```

Enjoy advanced WiFi capabilities on your ESP32-S3!
