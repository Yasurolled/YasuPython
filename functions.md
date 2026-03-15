# Function Documentation

## build.sh

This script is the primary build tool for the project. It ensures dependencies and environment setup, then runs ESP-IDF compilation and outputs a summary.

- `fail(msg)`:
  - Prints error message to console and exits with status 1.
  - Writes `build_error.log` with failure reason.

- `install_espidf()`:
  - Creates `/opt/esp-idf` and clones ESP-IDF v5.1.2 if missing.
  - Runs `./install.sh` and sources `export.sh`.
  - Tracks state for successful install or fails with log.

- ESP-IDF validation:
  - `idf.py --version` parsed with semantic regex.
  - Minimum required `5.1.2` enforced.

- MicroPython validator (optional):
  - Verifies `micropython` module availability in Python.
  - Attempts `pip3 install --user micropython`, and fallback `pip3 install micropython`.
  - Failure is non-blocking: script continues with warning.

- Clean build behavior:
  - Removes an existing `build/` directory to ensure a clean environment.
  - Runs `idf.py -B build fullclean build`.

- Firmware artifact handling:
  - Finds first `*.bin` under `build/`.
  - Copies to `build/esp32s3.bin`.
  - Prints summary fields: hardware, config, resilience, module status, binary size, firmware paths.


## raw_wifi.c

- `raw_wifi.inject(mp_obj_t data_obj)`:
  - `mp_obj_str_get_data(...)` with length extraction.
  - Allocates DMA-capable buffer (`heap_caps_malloc(len, MALLOC_CAP_DMA)`).
  - Copies raw payload including 0x00/0x0A bytes.
  - Frees buffer after placeholder packet "inject".
  - Throws `ValueError` on zero-length input.

- `raw_wifi.version()` returns version string.

- Module registration for MicroPython binding.


## raw_blue.c

- `raw_blue.inject(mp_obj_t data_obj)` analog to raw_wifi.
- `raw_blue.version()` returns version.
- Module registration for MicroPython binding.


## Notes
- Modules are designed for low-level raw packet injection proof-of-concept.
- Replace placeholder paths with actual radio stack calls for production.

---

Engineered by Yasu in collaboration with Gemini and GitHub Copilot.
