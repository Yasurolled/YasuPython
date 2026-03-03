#include "py/obj.h"
#include "py/runtime.h"
#include "esp_wifi.h"
#include <string.h>

static mp_obj_t wifi_pro_set_tx_power(mp_obj_t level_obj) {
    int level = mp_obj_get_int(level_obj);
    if (level < 0) level = 0;
    if (level > 84) level = 84;
    esp_err_t err = esp_wifi_set_max_tx_power(level);
    if (err != ESP_OK) {
        mp_raise_msg_varg(&mp_type_OSError, MP_ERROR_TEXT("TX Power Hatasi: %d"), err);
    }
    return mp_const_none;
}
static MP_DEFINE_CONST_FUN_OBJ_1(wifi_pro_set_tx_power_obj, wifi_pro_set_tx_power);

static mp_obj_t wifi_pro_send_raw(mp_obj_t packet_obj) {
    mp_buffer_info_t bufinfo;
    mp_get_buffer_raise(packet_obj, &bufinfo, MP_BUFFER_READ);

    // ESP32-S3 ham paket gönderimi
    esp_err_t err = esp_wifi_80211_tx(WIFI_IF_STA, bufinfo.buf, bufinfo.len, false);
    
    if (err != ESP_OK) {
        mp_raise_msg_varg(&mp_type_OSError, MP_ERROR_TEXT("esp_wifi_80211_tx failed: %d"), err);
    }
    return mp_const_none;
}
static MP_DEFINE_CONST_FUN_OBJ_1(wifi_pro_send_raw_obj, wifi_pro_send_raw);

static mp_obj_t wifi_pro_set_promiscuous(mp_obj_t state_obj) {
    bool state = mp_obj_is_true(state_obj);
    esp_wifi_set_promiscuous(state);
    return mp_const_none;
}
static MP_DEFINE_CONST_FUN_OBJ_1(wifi_pro_set_promiscuous_obj, wifi_pro_set_promiscuous);

static const mp_rom_map_elem_t wifi_pro_module_globals_table[] = {
    { MP_ROM_QSTR(MP_QSTR_set_tx_power), MP_ROM_PTR(&wifi_pro_set_tx_power_obj) },
    { MP_ROM_QSTR(MP_QSTR_send_raw), MP_ROM_PTR(&wifi_pro_send_raw_obj) },
    { MP_ROM_QSTR(MP_QSTR_set_promiscuous), MP_ROM_PTR(&wifi_pro_set_promiscuous_obj) },
};
static MP_DEFINE_CONST_DICT(wifi_pro_module_globals, wifi_pro_module_globals_table);

const mp_obj_module_t wifi_pro_user_cmodule = {
    .base = { &mp_type_module },
    .globals = (mp_obj_dict_t*)&wifi_pro_module_globals,
};

MP_REGISTER_MODULE(MP_QSTR_wifi_pro, wifi_pro_user_cmodule);