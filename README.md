# ESP WiFi 802.11 TX Module

Raw 802.11 frame transmission module for MicroPython on ESP32-S3.

## Quick Start

### 1. Build & Flash Firmware

```bash
cd micropython/ports/esp32
cp -r path/to/micropython_esp_wifi_tx modules/esp_wifi_tx

source ~/esp/esp-idf/export.sh
make BOARD=ESP32_S3
make BOARD=ESP32_S3 deploy
```

### 2. Use in Your Code

```python
import esp_wifi_tx
import network

# Initialize WiFi
sta = network.WLAN(network.STA_IF)
sta.active(True)

# Create your 802.11 frame (example: beacon)
frame = bytes([
    0x80, 0x00,  # Frame control
    0x00, 0x00,  # Duration
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,  # Destination
    0x11, 0x22, 0x33, 0x44, 0x55, 0x66,  # Source
    0x11, 0x22, 0x33, 0x44, 0x55, 0x66,  # BSSID
    0x00, 0x00,  # Sequence
])

# Send frame
ret = esp_wifi_tx.wifi_80211_tx(esp_wifi_tx.WIFI_IF_STA, frame)
if ret == 0:
    print("Success!")
```

## API Reference

### `wifi_80211_tx(interface, data, enable_sys_seq=True) -> int`

Send a raw 802.11 frame.

**Parameters:**
- `interface` (int): WiFi interface - `WIFI_IF_STA` (0) or `WIFI_IF_AP` (1)
- `data` (bytes): 802.11 frame bytes
- `enable_sys_seq` (bool): Auto-increment sequence number (default: True)

**Returns:**
- `0`: Success
- Negative: Error code

**Example:**
```python
import esp_wifi_tx

frame = bytes([...])
ret = esp_wifi_tx.wifi_80211_tx(esp_wifi_tx.WIFI_IF_STA, frame, True)
assert ret == 0, f"Failed: {ret}"
```

### Constants

- `WIFI_IF_STA`: Station interface (0)
- `WIFI_IF_AP`: Access point interface (1)

## Frame Types

### Beacon Frame
- Type: Management (0x80)
- Contains: SSID, capability info, supported rates
- Used by: APs to announce presence

### Probe Request
- Type: Management (0x40)
- Sent by: STAs searching for networks
- Responses: Probe responses from APs

### DeAuth/Disassoc
- Type: Management (0xA0, 0xC0)
- Function: Disconnect devices
- ⚠️ Highly regulated - check local laws

## File Structure

```
micropython_esp_wifi_tx/
├── esp_wifi_80211_tx.c       # C module implementation
├── manifest.py               # Build manifest
├── micropython.cmake         # CMake configuration
├── examples.py               # Usage examples
├── BUILD_INSTRUCTIONS.md     # Detailed build guide
└── README.md                 # This file
```

## Common Issues

| Issue | Solution |
|-------|----------|
| "module not found" | Firmware not built with module - rebuild |
| Error -2 | WiFi not initialized - call `network.WLAN()` |
| Error -1/-3 | Invalid frame - check 802.11 structure |
| Device crash | Malformed frame - validate before sending |

## Advanced Usage

### Capture & Resend
```python
import esp_wifi_tx
import network

sta = network.WLAN(network.STA_IF)
sta.active(True)

# Send captured frame from Wireshark
captured_frame = bytes.fromhex("8000000000ffffffffffff11223344556611223344556600000...")
esp_wifi_tx.wifi_80211_tx(esp_wifi_tx.WIFI_IF_STA, captured_frame)
```

### Frame Generation with Scapy (external tool)

Generate frames on computer, send via MicroPython:

```python
# Generated on PC with Scapy, then hex-encoded into device
frame_hex = "8000000000ffffffffffff..."
frame = bytes.fromhex(frame_hex)
esp_wifi_tx.wifi_80211_tx(esp_wifi_tx.WIFI_IF_STA, frame)
```

## Legal & Safety

⚠️ **Before using:**
1. Verify regulatory compliance (FCC, CE, etc.)
2. Test in isolated/lab environments
3. Don't interfere with production networks
4. Review local wireless regulations
5. Be aware of criminal liability for misuse

## Resources

- [802.11 Standards](https://en.wikipedia.org/wiki/IEEE_802.11)
- [Frame Format Details](https://en.wikipedia.org/wiki/Frame_(networking)#802.11_frame_types)
- [MicroPython Docs](https://docs.micropython.org/)
- [ESP-IDF WiFi API](https://docs.espressif.com/projects/esp-idf/en/latest/esp32s3/api-reference/network/esp_wifi.html)

## License

This module is provided as-is for educational and research purposes.

🚧Disclaimer🚧
In this repository the use of ai can be seen please if you see any error create pull request 
---

**Version**: 0.1.0  
**Device**: ESP32-S3 N16R8  
**Framework**: MicroPython 1.20+
