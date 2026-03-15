# ESP32-S3 (N16R8) High-Performance PenTest Framework

## Overview
This repository provides a high-performance proof-of-concept penetration testing framework for ESP32-S3 (N16R8). It includes low-level raw injection modules for WiFi and Bluetooth and is designed for experimental firmware development.

- Target platform: ESP32-S3 (N16R8)
- ESP-IDF version: 5.1.2+
- MicroPython dependency: 1.22+ (optional, best effort)
- Built modules: `raw_wifi`, `raw_blue`

## Requirements
- Ubuntu 24.04 (or similar Linux) recommended
- `python3`, `pip3`, `git`
- `build.sh` will install ESP-IDF under `/opt/esp-idf` if missing

## build.sh Behavior
`build.sh` is the main build orchestrator. It performs:
1. `idf.py` availability check and self-install of ESP-IDF (v5.1.2 branch) to `/opt/esp-idf`.
2. ESP-IDF version validation (`>=5.1.2`).
3. Attempt to install Python `micropython` package via `pip3` (silent warning if not available).
4. Clean `build/` folder and apply standard SDK config overrides for ESP32-S3 N16R8.
5. Run `idf.py -B build fullclean build` and capture output logs (`build.log` / `build_error.log`).
6. Locate the produced firmware `.bin`, copy to `build/esp32s3.bin`, and print a concise build summary.

## Quick Start
```bash
chmod +x build.sh
./build.sh
```

## Module API
### raw_wifi
- `raw_wifi.inject(data)`
  - Receives a Python bytes-like object
  - Allocates DMA-capable buffer (`MALLOC_CAP_DMA`)
  - Preserves payload exactly (including 0x00 and 0x0A)
  - Simulates injection path in placeholder code
- `raw_wifi.version()` returns module version

### raw_blue
- `raw_blue.inject(data)` same pattern for Bluetooth
- `raw_blue.version()` returns module version

## File Layout
- `build.sh` - main automation and build status
- `raw_wifi.c` - WiFi raw injection module
- `raw_blue.c` - Bluetooth raw injection module
- `functions.md` - function-level documentation and notes
- `github/` - GitHub packaging and CI pipeline files

## GitHub integration
There is a GitHub Actions workflow at `github/.github/workflows/ci.yml` for CI build runs.

---

Engineered by Yasu in collaboration with Gemini and GitHub Copilot.
