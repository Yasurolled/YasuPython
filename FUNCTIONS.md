# WiFi Pro Module – Function Reference

This document provides detailed documentation for each function in the `wifi_pro` module, including technical details, usage examples, and best practices.

## Table of Contents

1. [Overview](#overview)
2. [set_tx_power()](#set_tx_power)
3. [send_raw()](#send_raw)
4. [set_promiscuous()](#set_promiscuous)
5. [Advanced Usage](#advanced-usage)
6. [Error Handling](#error-handling)
7. [Common Pitfalls](#common-pitfalls)

---

## Overview

The `wifi_pro` module provides low-level WiFi control on the ESP32-S3 by wrapping ESP-IDF WiFi driver functions. It allows you to:

- **Control transmit power** for fine-grained RF control
- **Inject raw frames** for protocol development and testing
- **Enable promiscuous mode** for packet sniffing and analysis

### Module Import

```python
import wifi_pro
```

All functions are accessed as `wifi_pro.<function_name>()`.

---

## set_tx_power()

### Function Signature

```python
wifi_pro.set_tx_power(level)
```

### Parameters

| Parameter | Type    | Range           | Description                          |
|-----------|---------|-----------------|--------------------------------------|
| `level`   | int     | 0–84 (0–42 dBm) | TX power level in 0.25 dBm steps     |

### Return Value

- **None** – Function returns `None` on success
- **Raises `OSError`** – If the operation fails (see **Error Handling** below)

### Description

Sets the maximum WiFi transmit power for all subsequent transmissions. The ESP32-S3 WiFi transceiver supports 85 discrete power levels (0–84) corresponding to:

- **Level 0** = -11.5 dBm (minimum, low power)
- **Level 42** = 10.5 dBm (half power)
- **Level 84** = 20.5 dBm (maximum, full power)

**Internal Implementation:**
- Calls `esp_wifi_set_max_tx_power(level)` from ESP-IDF
- Sets the global TX power cap for the WiFi driver
- Affects all future transmissions until changed again
- Does not affect reception

### Usage Examples

#### Basic Usage – Set to Full Power

```python
import wifi_pro

# Set TX power to maximum (20.5 dBm ~ 84 level)
wifi_pro.set_tx_power(84)
print("TX power set to maximum")
```

#### Low Power Mode

```python
# Set to lower power (e.g., level 20 ≈ 0 dBm)
wifi_pro.set_tx_power(20)
print("TX power set to low (0 dBm)")
```

#### Fine-Grained Control

```python
# Set to 10 dBm (approximately level 80)
wifi_pro.set_tx_power(80)

# Set to 5 dBm (approximately level 70)
wifi_pro.set_tx_power(70)

# Set to 0 dBm (approximately level 42)
wifi_pro.set_tx_power(42)
```

#### Power Sweep for Testing

```python
import time

# Test sending at different power levels
power_levels = [20, 40, 60, 80, 84]

for level in power_levels:
    wifi_pro.set_tx_power(level)
    print(f"Testing at level {level}")
    # ... perform transmission test ...
    time.sleep(1)
```

### How It Works Internally

```
┌─────────────────────────────────────────────┐
│ MicroPython REPL                            │
│ wifi_pro.set_tx_power(84)                   │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ wifi_pro.c (C Module)                       │
│ wifi_pro_set_tx_power() function            │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ ESP-IDF WiFi Driver                         │
│ esp_wifi_set_max_tx_power(84)               │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ WiFi Hardware (PHY Layer)                   │
│ Sets RF amplifier gain & DAC levels         │
└─────────────────────────────────────────────┘
```

### Important Notes

- **Regulatory Compliance:** Some regions limit TX power. Check local regulations before using maximum power.
- **Thermal Considerations:** Maximum power (level 84) produces more heat. Ensure adequate ventilation.
- **Valid Ranges:** Level must be 0–84. Invalid values raise `OSError`.
- **Persistent During Session:** Power setting persists until explicitly changed or device reboots.
- **Initial Value:** Default TX power after boot is typically level 78 (≈19 dBm).

### Error Handling

```python
try:
    wifi_pro.set_tx_power(84)
except OSError as e:
    print(f"Failed to set TX power: {e}")
    # Typical error: "esp_wifi_set_max_tx_power failed: 258" (ESP_ERR_INVALID_ARG)
```

---

## send_raw()

### Function Signature

```python
wifi_pro.send_raw(packet)
```

### Parameters

| Parameter | Type             | Size Limit      | Description                        |
|-----------|------------------|-----------------|-------------------------------------|
| `packet`  | bytes or buffer  | 1–1500 bytes    | Complete IEEE 802.11 frame payload |

### Return Value

- **None** – Function returns `None` on success
- **Raises `OSError`** – If the operation fails

### Description

Sends a raw IEEE 802.11 frame (without WiFi data link layer encapsulation) directly to the air. This function bypasses normal WiFi stack processing and is useful for:

- **Protocol development** – Testing custom WiFi implementations
- **Penetration testing** – Security research (with proper authorization)
- **Frame injection** – Custom beacon/probe request crafting
- **Packet manipulation** – Modifying standard frames for analysis

**Internal Implementation:**
- Calls `esp_wifi_80211_tx(WIFI_IF_STA, buffer, length, ...)` from ESP-IDF
- Transmits on the currently configured WiFi channel
- Does NOT append WiFi FCS (frame check sequence) – you must include it
- Operates in Station (STA) mode by default

### Frame Format

Raw frames must follow IEEE 802.11 standard structure:

```
┌─────────┬──────────┬──────────┬──────────┬───────┐
│ Frame   │ Duration │ Address  │ Address  │ ...   │
│ Control │ / ID     │ 1–4      │ Fields   │ Payload│
├─ 2 Bytes├─2 Bytes─┤         └───────────┘       │
└─────────┴──────────┴──────────────────────────────┘
```

### Usage Examples

#### Send a Minimal Frame

```python
import wifi_pro

# Simplest raw frame (2-byte frame control + FCS placeholder)
minimal_frame = b"\x80\x00\x00\x00"  # Data frame, no flags
wifi_pro.send_raw(minimal_frame)
```

#### Send a Probe Request Frame

```python
# IEEE 802.11 Probe Request frame structure:
# Frame Control: 0x40 0x00 (Probe Request)
# Duration/ID: 0x00 0x00
# Destination: FF FF FF FF FF FF (broadcast)
# Source: 00 11 22 33 44 55 (your MAC)
# BSSID: 00 11 22 33 44 55 (same as source in probe request)

probe_request = bytes([
    0x40, 0x00,                              # Frame Control (Probe Request)
    0x00, 0x00,                              # Duration/ID
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff,      # Destination (broadcast)
    0x00, 0x11, 0x22, 0x33, 0x44, 0x55,      # Source MAC
    0x00, 0x11, 0x22, 0x33, 0x44, 0x55,      # BSSID
    0x00, 0x00,                              # Sequence Control
])

wifi_pro.send_raw(probe_request)
print("Probe request sent")
```

#### Send Multiple Frames in Sequence

```python
import time

frames = [
    b"\x40\x00\x00\x00\xff\xff...",  # Frame 1
    b"\x40\x00\x00\x00\xff\xff...",  # Frame 2
    b"\x40\x00\x00\x00\xff\xff...",  # Frame 3
]

for frame in frames:
    wifi_pro.send_raw(frame)
    time.sleep(0.1)  # Small delay between frames
```

#### Send with Error Handling

```python
import wifi_pro

def safe_send_raw(packet, retries=3):
    """Send raw frame with retries"""
    for attempt in range(retries):
        try:
            wifi_pro.send_raw(packet)
            print(f"Frame sent successfully (attempt {attempt + 1})")
            return True
        except OSError as e:
            print(f"Attempt {attempt + 1} failed: {e}")
            if attempt < retries - 1:
                time.sleep(0.1)
    return False

# Usage
packet = b"\x40\x00\x00\x00\xff\xff\xff\xff\xff\xff..."
safe_send_raw(packet)
```

### How It Works Internally

```
┌─────────────────────────────────────────────┐
│ MicroPython REPL                            │
│ wifi_pro.send_raw(packet_bytes)             │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ wifi_pro.c (C Module)                       │
│ wifi_pro_send_raw()                         │
│ - Extract buffer pointer & length           │
│ - Call esp_wifi_80211_tx()                  │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ ESP-IDF WiFi Driver                         │
│ Enqueue frame for transmission               │
│ Calculate FCS if needed                      │
│ Apply current TX power setting               │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ WiFi MAC Hardware                           │
│ Schedule transmission on current channel     │
│ Modulate and transmit RF signal              │
└─────────────────────────────────────────────┘
```

### Important Notes

- **Frame Check Sequence (FCS):** ESP-IDF may automatically compute and append the FCS. Do not include it yourself unless you're sure.
- **Channel Selection:** Frame transmits on the current WiFi channel. Use standard WiFi functions to change channels if needed.
- **Timing:** Frames are queued and transmitted asynchronously. There's no guarantee of exact timing.
- **Authentication State:** Some frame types may be blocked if WiFi is not properly initialized or connected.
- **Buffer Size:** Maximum frame size depends on ESP-IDF configuration, typically 1500 bytes.

### Frame Control Field Reference

Common Frame Control values (first 2 bytes as `0xFC 0x00` format):

| Frame Type          | Hex (Little-Endian) | Description                    |
|---------------------|---------------------|--------------------------------|
| Data                | `0x80 0x00`         | Standard data frame             |
| Probe Request       | `0x40 0x00`         | WiFi scanning probe             |
| Probe Response      | `0x50 0x00`         | WiFi scanning response          |
| Beacon              | `0x80 0x00`         | Access point beacon             |
| Deauthentication    | `0xa0 0x00`         | Deauth frame                    |

### Error Handling

```python
try:
    wifi_pro.send_raw(my_frame)
except OSError as e:
    error_code = e.args[0] if e.args else "Unknown"
    print(f"TX failed: {error_code}")
    # Common errors:
    # - 258: ESP_ERR_INVALID_ARG (bad buffer/length)
    # - 259: ESP_ERR_TIMEOUT (TX queue full)
    # - 4097: WiFi not initialized
```

---

## set_promiscuous()

### Function Signature

```python
wifi_pro.set_promiscuous(state)
```

### Parameters

| Parameter | Type    | Valid Values | Description                |
|-----------|---------|--------------|---------------------------|
| `state`   | bool    | `True/False` | Enable/disable promiscuous mode |

### Return Value

- **None** – Function returns `None` on success
- **Raises `OSError`** – If the operation fails

### Description

Enables or disables **promiscuous mode**, which puts the WiFi receiver into a state where it captures **all frames** on the current channel (not just frames addressed to this device). This is used for:

- **Packet sniffing** – Monitoring all WiFi traffic
- **Network analysis** – Studying WiFi behavior
- **Security scanning** – Finding rogue access points
- **Protocol research** – Understanding WiFi stack behavior

**Internal Implementation:**
- Calls `esp_wifi_set_promiscuous(state)` from ESP-IDF
- Does not require WiFi to be connected to an access point
- Operates independently of STA/AP mode
- Captured frames are passed to registered callback handlers

### Usage Examples

#### Basic Promiscuous Mode

```python
import wifi_pro

# Enable promiscuous mode
wifi_pro.set_promiscuous(True)
print("Promiscuous mode enabled – listening for all frames")

# ... do packet analysis ...

# Disable promiscuous mode
wifi_pro.set_promiscuous(False)
print("Promiscuous mode disabled")
```

#### Toggle Promiscuous Mode

```python
import wifi_pro
import time

def toggle_promiscuous(interval=5):
    """Toggle promiscuous mode every interval seconds"""
    enabled = False
    
    while True:
        wifi_pro.set_promiscuous(enabled)
        print(f"Promiscuous mode: {'ON' if enabled else 'OFF'}")
        time.sleep(interval)
        enabled = not enabled

# Usage (runs forever)
# toggle_promiscuous(interval=10)
```

#### Promiscuous Mode with Error Handling

```python
import wifi_pro

def safely_enable_promiscuous():
    """Enable promiscuous mode with error handling"""
    try:
        wifi_pro.set_promiscuous(True)
        return True
    except OSError as e:
        print(f"Could not enable promiscuous mode: {e}")
        return False

def safely_disable_promiscuous():
    """Disable promiscuous mode with error handling"""
    try:
        wifi_pro.set_promiscuous(False)
        return True
    except OSError as e:
        print(f"Could not disable promiscuous mode: {e}")
        return False

# Usage
if safely_enable_promiscuous():
    print("Promiscuous mode is active")
    # ... capture and analyze frames ...
    safely_disable_promiscuous()
```

#### Monitor for Specific Frame Types

```python
import wifi_pro
import time

def monitor_beacons(duration=30):
    """Listen for beacon frames for specified duration"""
    wifi_pro.set_promiscuous(True)
    print(f"Listening for beacons for {duration} seconds...")
    
    start_time = time.time()
    beacon_count = 0
    
    while time.time() - start_time < duration:
        # In a real implementation, you'd register a callback
        # to receive and count frames
        time.sleep(0.1)
    
    wifi_pro.set_promiscuous(False)
    print(f"Monitoring complete. Beacons detected: {beacon_count}")
    
monitor_beacons(duration=10)
```

### How It Works Internally

```
┌─────────────────────────────────────────────┐
│ MicroPython REPL                            │
│ wifi_pro.set_promiscuous(True)              │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ wifi_pro.c (C Module)                       │
│ wifi_pro_set_promiscuous() function         │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ ESP-IDF WiFi Driver                         │
│ esp_wifi_set_promiscuous(true)              │
│ - Disable MAC address filtering             │
│ - Enable frame type acceptance              │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ WiFi MAC Hardware                           │
│ Pass all received frames to driver           │
│ (normally: drop non-destined frames)        │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ Application                                  │
│ Receives frames via callback/interface      │
│ Can analyze/sniff traffic                    │
└─────────────────────────────────────────────┘
```

### Important Notes

- **Power Consumption:** Promiscuous mode increases CPU and radio utilization. Power draw increases significantly.
- **Channel Specific:** Only receives frames on the current channel. Channel switching stops reception.
- **No Address Filtering:** All frames received, regardless of BSSID or destination address.
- **Regulatory Note:** Packet sniffing may be regulated in some jurisdictions when targeting other networks.
- **Performance Impact:** High frame rate may cause frame drops due to processing delays.

### Frame Reception

When promiscuous mode is enabled, the WiFi driver can deliver frames via:

1. **RxControl callback** – Metadata (RSSI, channel, rate, etc.)
2. **Frame payload** – The actual 802.11 frame data

Standard MicroPython espressif port integrates frame reception, but you need to register callbacks in your custom code if you want to process received frames.

### Error Handling

```python
try:
    wifi_pro.set_promiscuous(True)
except OSError as e:
    print(f"Failed to enable promiscuous mode: {e}")
    # Possible errors:
    # - ESP_ERR_WIFI_NOT_INIT: WiFi not initialized
    # - ESP_ERR_WIFI_NOT_STARTED: WiFi not started
    # - 259: ESP_ERR_TIMEOUT
```

---

## Advanced Usage

### Combining Functions

```python
import wifi_pro
import time

# Workflow: Low-power transmission mode with frame injection
wifi_pro.set_tx_power(40)  # Set to 5 dBm (low power)

# Create frames
frames = [
    b"\x40\x00\x00\x00\xff\xff\xff\xff\xff\xff\x00\x11\x22\x33\x44\x55\x00\x11\x22\x33\x44\x55\x00\x00",
    b"\x40\x00\x00\x00\xff\xff\xff\xff\xff\xff\x00\x11\x22\x33\x44\x55\x00\x11\x22\x33\x44\x55\x00\x01",
]

# Send frames at controlled power
for frame in frames:
    try:
        wifi_pro.send_raw(frame)
        print(f"Frame sent (TX power: 5 dBm)")
    except OSError as e:
        print(f"Error: {e}")
    time.sleep(0.5)

# Listen for responses
wifi_pro.set_promiscuous(True)
print("Listening for responses...")
time.sleep(5)
wifi_pro.set_promiscuous(False)
```

### Monitoring and Adjustment

```python
import wifi_pro
import time

class WiFiMonitor:
    def __init__(self):
        self.tx_power = 84
        self.promiscuous = False
    
    def enable_monitoring(self):
        wifi_pro.set_promiscuous(True)
        self.promiscuous = True
    
    def disable_monitoring(self):
        wifi_pro.set_promiscuous(False)
        self.promiscuous = False
    
    def set_power(self, level):
        wifi_pro.set_tx_power(level)
        self.tx_power = level
    
    def adaptive_power(self, signal_strength):
        """Adjust TX power based on received signal strength"""
        if signal_strength < -80:
            self.set_power(84)  # Max power for weak signal
        elif signal_strength < -70:
            self.set_power(60)
        else:
            self.set_power(40)  # Lower power for strong signal
        print(f"Adjusted TX power to {self.tx_power}")

# Usage
monitor = WiFiMonitor()
monitor.enable_monitoring()
monitor.adaptive_power(-75)  # Adjust based on RSSI
monitor.disable_monitoring()
```

---

## Error Handling

### Common Error Codes

| Error Code | Constant              | Meaning                          | Solution                         |
|------------|----------------------|----------------------------------|----------------------------------|
| 0          | ESP_OK                | Success                          | N/A                              |
| 258        | ESP_ERR_INVALID_ARG   | Invalid parameter                | Check parameter range/type       |
| 259        | ESP_ERR_TIMEOUT       | Operation timed out              | Retry or check device state      |
| 4097       | ESP_ERR_WIFI_NOT_INIT | WiFi not initialized             | Initialize WiFi first            |
| 4098       | ESP_ERR_WIFI_NOT_ACTL | WiFi not activated               | Start WiFi mode                  |

### Error Handling Pattern

```python
import wifi_pro

def safe_operation(func, *args, max_retries=3):
    """Generic error handling wrapper"""
    for attempt in range(max_retries):
        try:
            return func(*args)
        except OSError as e:
            print(f"Attempt {attempt + 1}/{max_retries} failed: {e}")
            if attempt < max_retries - 1:
                time.sleep(0.1)
    print("Operation failed after all retries")
    return False

# Usage
safe_operation(wifi_pro.set_tx_power, 84)
safe_operation(wifi_pro.set_promiscuous, True)
```

---

## Common Pitfalls

### 1. **Forgetting to Check Return Values**

❌ **Bad:**
```python
wifi_pro.set_tx_power(100)  # Invalid level
# Program continues without knowing it failed
```

✅ **Good:**
```python
try:
    wifi_pro.set_tx_power(84)  # Valid (0-84)
except OSError as e:
    print(f"Error: {e}")
```

### 2. **Mixing Up Raw Frame Structure**

❌ **Bad:**
```python
# Forgetting frame control bytes
frame = b"Send me a packet"
wifi_pro.send_raw(frame)  # This won't work
```

✅ **Good:**
```python
# Include proper IEEE 802.11 headers
frame = b"\x80\x00\x00\x00" + b"Payload"
wifi_pro.send_raw(frame)
```

### 3. **Not Initializing WiFi First**

❌ **Bad:**
```python
import wifi_pro
wifi_pro.set_promiscuous(True)  # WiFi might not be initialized
```

✅ **Good:**
```python
import network
import wifi_pro

wlan = network.WLAN(network.STA_IF)
wlan.active(True)  # Initialize WiFi
wifi_pro.set_promiscuous(True)
```

### 4. **Excessive TX Power Usage**

❌ **Bad:**
```python
# Always using maximum power
for i in range(1000):
    wifi_pro.set_tx_power(84)
    # Device gets hot
```

✅ **Good:**
```python
# Use appropriate power for your needs
wifi_pro.set_tx_power(60)  # Moderate power
for i in range(1000):
    wifi_pro.send_raw(frame)
```

### 5. **Not Disabling Promiscuous Mode**

❌ **Bad:**
```python
wifi_pro.set_promiscuous(True)
# App crashes or ends
# Promiscuous mode still active (power drain)
```

✅ **Good:**
```python
import wifi_pro

try:
    wifi_pro.set_promiscuous(True)
    # ... do work ...
finally:
    wifi_pro.set_promiscuous(False)  # Ensure cleanup
```

---

## Summary

| Function              | Purpose                        | Key Constraint          |
|----------------------|--------------------------------|------------------------|
| `set_tx_power()`     | Control WiFi RF power output    | Level 0–84              |
| `send_raw()`         | Inject custom WiFi frames       | Must be valid 802.11    |
| `set_promiscuous()`  | Capture all WiFi frames         | Increases power draw    |

For more details, see the [main README](README.md) and `user_c_modules/wifi_pro/wifi_pro.c`.
