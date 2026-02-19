#include <stdio.h>
#include <string.h>
#include "py/runtime.h"
#include "py/obj.h"
#include "py/objbytes.h"
#include "esp_wifi.h"

// MicroPython WiFi interface enum
typedef enum {
    WIFI_IF_STA = 0,    // Station mode
    WIFI_IF_AP = 1      // Access point mode
} mp_wifi_interface_t;

/**
 * MicroPython wrapper for esp_wifi_80211_tx
 * Transmits raw 802.11 frames
 * 
 * Syntax: esp_wifi_80211_tx(interface, data, enable_sys_seq)
 * 
 * Args:
 *   interface: 0 for STA, 1 for AP
 *   data: bytes object containing the raw 802.11 frame
 *   enable_sys_seq: bool, whether to use system sequence number
 * 
 * Returns: int (0 on success, error code on failure)
 */
STATIC mp_obj_t esp_wifi_80211_tx_func(size_t n_args, const mp_obj_t *args) {
    // Check argument count
    if (n_args < 2 || n_args > 3) {
        mp_raise_TypeError("esp_wifi_80211_tx() takes 2 or 3 arguments");
    }

    // Parse interface argument
    mp_int_t interface = mp_obj_get_int(args[0]);
    if (interface < WIFI_IF_STA || interface > WIFI_IF_AP) {
        mp_raise_ValueError("invalid WiFi interface (0 for STA, 1 for AP)");
    }

    // Parse data argument (bytes)
    mp_buffer_info_t buf_info;
    mp_get_buffer_raise(args[1], &buf_info, MP_BUFFER_READ);
    
    if (buf_info.len == 0) {
        mp_raise_ValueError("frame data cannot be empty");
    }

    // Parse enable_sys_seq argument (default: true)
    bool enable_sys_seq = true;
    if (n_args == 3) {
        enable_sys_seq = mp_obj_is_true(args[2]);
    }

    // Call the ESP-IDF function
    int ret = esp_wifi_80211_tx((wifi_interface_t)interface, buf_info.buf, buf_info.len, enable_sys_seq);

    // Return result code
    return mp_obj_new_int(ret);
}
STATIC MP_DEFINE_CONST_FUN_OBJ_VAR(esp_wifi_80211_tx_obj, 2, esp_wifi_80211_tx_func);

/**
 * Module initialization
 */
STATIC const mp_rom_map_elem_t esp_wifi_tx_module_globals_table[] = {
    { MP_ROM_QSTR(MP_QSTR___name__), MP_ROM_QSTR(MP_QSTR_esp_wifi_tx) },
    { MP_ROM_QSTR(MP_QSTR_wifi_80211_tx), MP_ROM_PTR(&esp_wifi_80211_tx_obj) },
    
    // WiFi interface constants
    { MP_ROM_QSTR(MP_QSTR_WIFI_IF_STA), MP_ROM_INT(WIFI_IF_STA) },
    { MP_ROM_QSTR(MP_QSTR_WIFI_IF_AP), MP_ROM_INT(WIFI_IF_AP) },
};

STATIC MP_DEFINE_CONST_DICT(esp_wifi_tx_module_globals, esp_wifi_tx_module_globals_table);

const mp_obj_module_t mp_module_esp_wifi_tx = {
    .base = { &mp_type_module },
    .globals = (mp_obj_dict_t *)&esp_wifi_tx_module_globals,
};

// Register the module
MP_REGISTER_MODULE(MP_QSTR_esp_wifi_tx, mp_module_esp_wifi_tx);
