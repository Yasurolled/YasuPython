#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"

static const char *TAG = "asdas_main";

void app_main(void) {
    ESP_LOGI(TAG, "Starting minimal ESP32-S3 test application");
    while (1) {
        vTaskDelay(pdMS_TO_TICKS(5000));
        ESP_LOGI(TAG, "Heartbeat");
    }
}
