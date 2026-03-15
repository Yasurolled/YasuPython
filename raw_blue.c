#include "py/obj.h"
#include "py/runtime.h"
#include "esp_heap_caps.h"
#include "esp_log.h"

#define TAG "raw_blue"

STATIC mp_obj_t raw_blue_inject(mp_obj_t data_obj) {
    size_t len;
    const byte *data = (const byte *)mp_obj_str_get_data(data_obj, &len);

    if (len == 0) {
        mp_raise_ValueError("raw_blue.inject: data length must be > 0");
    }

    void *dma_buf = heap_caps_malloc(len, MALLOC_CAP_DMA);
    if (!dma_buf) {
        mp_raise_OSError(MP_ENOMEM);
    }

    memcpy(dma_buf, data, len);

    // Zero-Filter Injection semantics: preserve 0x00 and 0x0A exactly
    // and do not modify the payload at driver layer.
    // Real injection logic should call ESP-IDF Bluetooth driver API.
    ESP_LOGI(TAG, "[raw_blue] Injecting %zu bytes", len);

    // Emulate successful queue action (replace with IDF tx call):
    bool result = true;

    heap_caps_free(dma_buf);

    if (!result) {
        mp_raise_msg(&mp_type_RuntimeError, "raw_blue.inject failed");
    }

    return mp_const_none;
}
STATIC MP_DEFINE_CONST_FUN_OBJ_1(raw_blue_inject_obj, raw_blue_inject);

STATIC mp_obj_t raw_blue_version(void) {
    return mp_obj_new_str("raw_blue v1.0 (ESP32-S3 N16R8)", strlen("raw_blue v1.0 (ESP32-S3 N16R8)"));
}
STATIC MP_DEFINE_CONST_FUN_OBJ_0(raw_blue_version_obj, raw_blue_version);

STATIC const mp_rom_map_elem_t raw_blue_module_globals_table[] = {
    { MP_ROM_QSTR(MP_QSTR___name__), MP_ROM_QSTR(MP_QSTR_raw_blue) },
    { MP_ROM_QSTR(MP_QSTR_inject), MP_ROM_PTR(&raw_blue_inject_obj) },
    { MP_ROM_QSTR(MP_QSTR_version), MP_ROM_PTR(&raw_blue_version_obj) },
};
STATIC MP_DEFINE_CONST_DICT(raw_blue_module_globals, raw_blue_module_globals_table);

const mp_obj_module_t raw_blue_module = {
    .base = { &mp_type_module },
    .globals = (mp_obj_dict_t *)&raw_blue_module_globals,
};

MP_REGISTER_MODULE(MP_QSTR_raw_blue, raw_blue_module, 1);
