# ESP WiFi 802.11 TX - Quick Reference

## Get Started

```bash
# 1. Clone MicroPython
git clone https://github.com/micropython/micropython.git
cd micropython

# 2. Copy module to MicroPython
cp -r /path/to/micropython_esp_wifi_tx/. ports/esp32/modules/esp_wifi_tx/

# 3. Build and flash
cd ports/esp32
source ~/esp/esp-idf/export.sh
make BOARD=ESP32_S3
make BOARD=ESP32_S3 deploy
```

## Usage

```python
import esp_wifi_tx
import network

# Initialize WiFi
sta = network.WLAN(network.STA_IF)
sta.active(True)

# Create 802.11 frame
frame = bytes([0x80, 0x00, ...])

# Send it
ret = esp_wifi_tx.wifi_80211_tx(esp_wifi_tx.WIFI_IF_STA, frame)
```

## API

| Function | Purpose |
|----------|---------|
| `wifi_80211_tx(iface, data, sys_seq=True)` | Send raw 802.11 frame |

| Return Value | Meaning |
|---|---|
| `0` | Success |
| `-1` | Invalid interface |
| `-2` | WiFi not init |
| `-3` | Invalid frame |
| `< 0` | Error |

| Constant | Value |
|----------|-------|
| `WIFI_IF_STA` | 0 |
| `WIFI_IF_AP` | 1 |

## 802.11 Frame Anatomy

```
Frame Control (2B) | Duration (2B) | Addr1 (6B) | Addr2 (6B) | 
Addr3 (6B) | Seq (2B) | [Addr4 (6B)] | Body (0-2312B)
```

**Frame Control Byte 1:**
```
Bit 7-4: Subtype  | Bit 3-2: Type | Bit 1: To DS | Bit 0: From DS
----------|----------|--------|----------
0x80: Beacon | 0x40: Probe Req | 0xA0: DeAuth | 0xC0: Disassoc
```

## Common Frame Types

| Type | Hex | Subtype | Purpose |
|------|-----|---------|---------|
| Data Frame | 0x08 | Various | Data transmission |
| Beacon | 0x80 | 0x00 | AP announcement |
| ProbeReq | 0x40 | 0x00 | Search for networks |
| ProbeRsp | 0x50 | 0x00 | AP responds to probe |
| DeAuth | 0xA0 | 0x00 | Disconnect device |
| Disassoc | 0xC0 | 0x00 | Remove associated device |

## Example: Send Beacon

```python
import esp_wifi_tx
import network

sta = network.WLAN(network.STA_IF)
sta.active(True)

# Minimal beacon
beacon = bytes([
    0x80, 0x00,           # Frame control + flags
    0x00, 0x00,           # Duration
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,  # Dest (broadcast)
    0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF,  # Source MAC
    0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF,  # BSSID
    0x00, 0x00,           # Sequence
    # Beacon-specific fields would go here
    0x00, 0x00, 0x00, 0x00,
])

ret = esp_wifi_tx.wifi_80211_tx(esp_wifi_tx.WIFI_IF_STA, beacon)
print(f"Sent: {ret}")
```

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| Module not found | Not in firmware | Rebuild with module |
| `-2` return | WiFi not ready | Call `sta.active(True)` |
| `-1` return | Bad interface | Use 0 or 1 |
| Device reboots | Bad frame | Check 802.11 structure |

## File Layout

```
micropython/
  ports/esp32/
    modules/
      esp_wifi_tx/
        ├── esp_wifi_80211_tx.c     (C implementation)
        ├── manifest.py             (Build config)
        └── micropython.cmake       (CMake settings)
```

## Building Options

```bash
# Clean build
make clean
make BOARD=ESP32_S3 -j$(nproc)

# Flash only
make BOARD=ESP32_S3 deploy

# With extra features
make BOARD=ESP32_S3 MICROPY_ENABLE_ALL_FEATURES=1
```

## Testing

```python
# Copy to device via USB
import esp_wifi_tx
print(esp_wifi_tx.WIFI_IF_STA)  # Should print 0
```

Or run the test suite:
```python
# Upload test_module.py to device
exec(open('test_module.py').read())
```

## Resources

- [ESP-IDF WiFi API](https://docs.espressif.com/projects/esp-idf/en/latest/esp32s3/api-reference/network/esp_wifi.html)
- [802.11 Beacon Frames](https://en.wikipedia.org/wiki/Beacon_frame)
- [MicroPython C Modules](https://docs.micropython.org/en/latest/develop/cmodules.html)
- [Scapy WiFi](https://scapy.readthedocs.io/)

## Key Limitations

- Frames must be valid 802.11 format
- Minimum 24 bytes (header only)
- Maximum ~2300 bytes (with body)
- Cannot transmit while not connected (in some modes)
- Regulatory compliance required

## Safety Warnings ⚠️

```
DO NOT:
❌ Use for network attacks
❌ Interfere with existing networks
❌ Violate local regulations
❌ Send malformed frames continuously
❌ Send frames without proper authorization

DO:
✓ Test in isolated lab environment
✓ Verify regulatory compliance
✓ Validate frame structure
✓ Use for research only
✓ Document your usage
```

---

**Quick Build:** 
```bash
bash build.sh
```

**Quick Test:**
```python
import esp_wifi_tx
esp_wifi_tx.wifi_80211_tx(0, bytes([0]*30))  # Should return 0 or negative (not exception)
```
