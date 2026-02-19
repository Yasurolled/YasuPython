# Project Overview

You now have a complete ESP WiFi 802.11 TX module for MicroPython on your ESP32-S3 N16R8!

## What You Have

### 📁 Project Structure

```
micropython_esp_wifi_tx/
├── esp_wifi_80211_tx.c        ← C module (main implementation)
├── manifest.py                 ← Build manifest
├── micropython.cmake          ← CMake config
├── build.sh                   ← Automated build script
├── README.md                  ← Quick start guide
├── QUICK_REFERENCE.md         ← Cheat sheet & API
├── BUILD_INSTRUCTIONS.md      ← Detailed build guide
├── examples.py                ← Code examples
├── test_module.py             ← Test suite
└── PROJECT_OVERVIEW.md        ← This file
```

## File Descriptions

### Core Implementation

| File | Purpose |
|------|---------|
| `esp_wifi_80211_tx.c` | C implementation that wraps ESP-IDF's `esp_wifi_80211_tx` function for MicroPython |
| `manifest.py` | Tells MicroPython build system to include this module |
| `micropython.cmake` | CMake configuration for building the module |

### Documentation

| File | Purpose |
|------|---------|
| `README.md` | Quick start, API reference, common issues |
| `QUICK_REFERENCE.md` | One-page cheat sheet with examples |
| `BUILD_INSTRUCTIONS.md` | Detailed step-by-step build guide |
| `PROJECT_OVERVIEW.md` | This file - project structure overview |

### Utilities

| File | Purpose |
|------|---------|
| `build.sh` | Automated build & flash script (Linux/macOS) |
| `examples.py` | Real-world usage examples |
| `test_module.py` | Test suite to verify module works |

## Quick Start (3 Steps)

### Step 1: Build the Firmware
```bash
bash micropython_esp_wifi_tx/build.sh
```

The script will:
- Clone MicroPython if needed
- Copy the module
- Build for ESP32-S3
- Ask if you want to flash

### Step 2: Flash to Device
```bash
bash micropython_esp_wifi_tx/build.sh ESP32_S3 /dev/ttyUSB0 460800
# Choose 'y' when prompted
```

### Step 3: Use in Python
```python
import esp_wifi_tx
import network

sta = network.WLAN(network.STA_IF)
sta.active(True)

# Send raw 802.11 frame
frame = bytes([0x80, 0x00, ...])
ret = esp_wifi_tx.wifi_80211_tx(esp_wifi_tx.WIFI_IF_STA, frame)
```

## Module API

### Function
```python
esp_wifi_tx.wifi_80211_tx(interface, data, enable_sys_seq=True) -> int
```

**Parameters:**
- `interface`: 0 (STA) or 1 (AP)
- `data`: bytes - raw 802.11 frame
- `enable_sys_seq`: bool - auto-increment sequence number (optional, default=True)

**Returns:**
- 0 = Success
- Negative = Error code

### Constants
- `esp_wifi_tx.WIFI_IF_STA` = 0 (Station mode)
- `esp_wifi_tx.WIFI_IF_AP` = 1 (Access Point mode)

## Which File to Read?

| You want to... | Read this |
|---|---|
| Get started quickly | `README.md` |
| See code examples | `examples.py` |
| Know all details | `BUILD_INSTRUCTIONS.md` |
| Just the API | `QUICK_REFERENCE.md` |
| Ensure it works | `test_module.py` |
| Automate build | Run `build.sh` |

## Building Without the Script

If `build.sh` doesn't work on your system:

```bash
cd micropython
git submodule update --init
cd mpy-cross && make && cd ..

cp -r /path/to/micropython_esp_wifi_tx ports/esp32/modules/esp_wifi_tx

cd ports/esp32
source ~/esp/esp-idf/export.sh
make BOARD=ESP32_S3
make BOARD=ESP32_S3 deploy
```

## Features Provided

✓ Raw 802.11 frame transmission  
✓ STA and AP mode support  
✓ System sequence number handling  
✓ Error codes for debugging  
✓ Full MicroPython integration  
✓ Proper C module with bindings  

## Known Limitations

- Frames must be valid 802.11 format (no validation)
- Minimum 24 bytes (frame header)
- Maximum ~2300 bytes total
- Requires WiFi to be initialized first
- Subject to local regulatory requirements

## Testing

After flashing, connect to your device and run:

```python
>>> import esp_wifi_tx
>>> print(esp_wifi_tx.WIFI_IF_STA)
0

# Run full test suite
>>> exec(open('test_module.py').read())
```

Or upload `test_module.py` and run it:
```bash
mpremote put test_module.py
mpremote run test_module.py
```

## Device Info

- **Device**: ESP32-S3 N16R8
- **Framework**: MicroPython 1.20+
- **ESP-IDF**: 5.0+
- **Module Version**: 0.1.0

## Support & Troubleshooting

1. **Module not found after flashing?**
   - Rebuild: `make clean && make BOARD=ESP32_S3`
   - Verify file exists: `ls micropython/ports/esp32/modules/esp_wifi_tx/`

2. **Function returns error code?**
   - Ensure WiFi is active: `sta.active(True)`
   - Check frame structure (minimum 24 bytes)
   - Verify interface (0 or 1)

3. **Device crashes when sending frame?**
   - Frame structure may be invalid
   - Try minimal frame first (see examples.py)
   - Check 802.11 frame format specification

4. **Build fails?**
   - Check IDF_PATH: `echo $IDF_PATH`
   - Update toolchain: `pip install --upgrade esptool`
   - See BUILD_INSTRUCTIONS.md for detailed steps

## Legal & Safety

⚠️ **Important**: Raw WiFi frame transmission is regulated in most countries. Before using:

1. ✓ Check FCC/CE regulations for your region
2. ✓ Only test in isolated environments
3. ✓ Do not interfere with production networks
4. ✓ Have proper authorization
5. ✓ Understand potential legal implications

This module is for **educational and authorized security testing only**.

## Next Steps

1. Read `README.md` for quick start
2. Run `build.sh` to build firmware
3. Flash to your ESP32-S3
4. Try the examples in `examples.py`
5. Run `test_module.py` to verify
6. Refer to `QUICK_REFERENCE.md` for API details

## File Versions

- `esp_wifi_80211_tx.c` - v0.1.0
- All documentation - Updated Feb 2026
- Compatible with MicroPython 1.20+

---

**You're ready to build!** 🚀

Start with:
```bash
bash micropython_esp_wifi_tx/build.sh
```

Questions? Check the appropriate documentation file above.
