# ESP WiFi 802.11 TX Module for MicroPython (ESP32-S3)

This module exposes the `esp_wifi_80211_tx` function from the ESP-IDF to MicroPython, allowing you to transmit raw 802.11 frames on your ESP32-S3.

## Prerequisites

- ESP32-S3 N16R8 device
- MicroPython source code for ESP32
- ESP-IDF (compatible with your MicroPython version)
- Build tools: gcc, make, python3, cmake

## Installation Methods

### Method 1: Build Custom MicroPython Firmware (Recommended)

#### Step 1: Clone MicroPython Repository
```bash
git clone https://github.com/micropython/micropython.git
cd micropython
```

#### Step 2: Update Submodules
```bash
git submodule update --init
cd mpy-cross
make
cd ..
```

#### Step 3: Copy Module to MicroPython

Copy the `micropython_esp_wifi_tx` directory to MicroPython's modules:

```bash
cp -r /path/to/micropython_esp_wifi_tx micropython/ports/esp32/modules/esp_wifi_tx
```

#### Step 4: Build for ESP32-S3

Navigate to the ESP32 port:

```bash
cd micropython/ports/esp32
```

If you haven't set up the environment, do so first:

```bash
# Install ESP-IDF (if not already installed)
./setup.sh

# Or if you have IDF_PATH set:
source ~/esp/esp-idf/export.sh
```

Build the firmware:

```bash
# Clean previous builds
make clean

# Build for ESP32-S3
make BOARD=ESP32_S3
```

#### Step 5: Flash to Device

```bash
make BOARD=ESP32_S3 deploy

# Or manually:
esptool.py -p /dev/ttyUSB0 -b 460800 --before default_reset --after hard_reset \
    --chip esp32s3 write_flash -z --flash_mode dio --flash_freq 80m \
    --flash_size 16MB 0x0 build-ESP32_S3/firmware.bin
```

### Method 2: As a User Module (Without Rebuilding Core)

If you already have MicroPython running on your ESP32-S3:

1. Compile just this module:
```bash
cd micropython/ports/esp32
make USER_C_MODULES=../../../micropython_esp_wifi_tx BOARD=ESP32_S3
```

2. Flash the generated firmware

## Usage

### Basic Example

```python
import esp_wifi_tx

# Send a raw 802.11 frame
frame_data = bytes([0x80, 0x00, ...])  # Your 802.11 frame data

# Constants for WiFi interface
WIFI_IF_STA = esp_wifi_tx.WIFI_IF_STA  # 0
WIFI_IF_AP = esp_wifi_tx.WIFI_IF_AP    # 1

# Send frame on STA interface with system sequence number
result = esp_wifi_tx.wifi_80211_tx(WIFI_IF_STA, frame_data, True)

if result == 0:
    print("Frame sent successfully")
else:
    print(f"Error: {result}")
```

### Function Signature

```python
esp_wifi_tx.wifi_80211_tx(interface, data, enable_sys_seq=True) -> int
```

**Parameters:**
- `interface` (int): 0 for STA mode, 1 for AP mode
- `data` (bytes): Raw 802.11 frame data (minimum length required by standard)
- `enable_sys_seq` (bool, optional): Use system sequence number (default: True)

**Returns:**
- 0 on success
- Negative error code on failure

### Error Codes

Common error codes returned by `esp_wifi_80211_tx`:
- `0`: Success
- `-1`: Invalid interface
- `-2`: WiFi not initialized
- `-3`: Invalid frame data
- `-4`: Other driver errors

See ESP-IDF documentation for complete error code reference.

## 802.11 Frame Structure

Raw 802.11 frames require proper structure. Here's the basic format:

```
Frame Control (2 bytes)
    ├─ Frame Type/Subtype
    ├─ Flags (To DS, From DS, etc.)
    └─ ...

Duration/ID (2 bytes)

Address 1 - Receiver MAC (6 bytes)
Address 2 - Transmitter MAC (6 bytes)
Address 3 - BSSID (6 bytes)
Sequence Control (2 bytes)
[Address 4 - only in specific frame types (6 bytes)]

Frame Body (variable length, 0-2312 bytes)
FCS - Frame Check Sequence (4 bytes - may be calculated automatically)
```

For beacon frames, management frames, etc., you'll need to construct the appropriate structure.

## Safety Notes

⚠️ **Important Warnings:**

1. **Regulatory Compliance**: Transmitting raw WiFi frames may violate local regulations. Ensure compliance with FCC, CE, or your local regulatory authority.

2. **Network Interference**: Improperly formed frames can interfere with WiFi networks. Test in isolated environments.

3. **Security**: This function can be used for packet injection attacks. Use responsibly and ethically.

4. **WiFi Initialization**: WiFi must be initialized before using this function. Ensure you've called `network.WLAN()` first.

5. **Frame Validity**: The ESP-IDF may not validate frame structure. Invalid frames can crash the driver.

## Debugging

### Enable WiFi Logging

In your MicroPython code:

```python
import esp
esp.osdebug(1)  # Enable OS debug output
```

### Common Issues

1. **Module not found**: Make sure firmware was built with the module included
2. **Error -2**: WiFi not initialized - call `network.WLAN()` first
3. **Error -1 or -3**: Invalid frame data - check frame structure
4. **Device crash/reboot**: Invalid frame structure - add validation

## Building with platformio

Alternative build option using platformio:

```bash
# Create platformio.ini with custom module path
[env:esp32-s3-devkitc-1]
platform = espressif32
board = esp32-s3-devkitc-1
framework = micropython
custom_module_path = ./micropython_esp_wifi_tx
```

## Advanced: Custom Compilation Options

To enable additional WiFi features:

```bash
cd micropython/ports/esp32
make BOARD=ESP32_S3 \
    MICROPY_PY_NETWORK_HOSTNAME=1 \
    MICROPY_ENABLE_ALL_FEATURES=1
```

## References

- [MicroPython ESP32 Documentation](https://docs.micropython.org/en/latest/esp32/quickref.html)
- [ESP-IDF WiFi API](https://docs.espressif.com/projects/esp-idf/en/latest/esp32s3/api-reference/network/esp_wifi.html)
- [802.11 Frame Format](https://en.wikipedia.org/wiki/Frame_(networking)#802.11_frame_types)
- [Scapy WiFi Examples](https://scapy.readthedocs.io/en/latest/)

## Troubleshooting Build Issues

### Missing esp_wifi.h

Make sure IDF_PATH environment variable is set correctly:
```bash
export IDF_PATH=~/esp/esp-idf
```

### CMake errors

Update to latest cmake:
```bash
pip install --upgrade cmake
```

### Permission errors on serial port

```bash
sudo usermod -a -G dialout $USER
# Log out and back in
```

## Support

For issues specific to this module, refer to the examples.py file.
For ESP-IDF issues, check the [official documentation](https://docs.espressif.com/projects/esp-idf/en/latest/).

---

**Version**: 0.1.0  
**Compatible with**: MicroPython 1.20+, ESP32-S3, ESP-IDF 5.0+
