"""
Manifest for esp_wifi_80211_tx module
Integrates raw WiFi frame transmission into MicroPython
"""

metadata(
    version="0.1.0",
    description="ESP-IDF esp_wifi_80211_tx wrapper for MicroPython"
)

# Include the C module
module("esp_wifi_80211_tx.c", opt=3)
