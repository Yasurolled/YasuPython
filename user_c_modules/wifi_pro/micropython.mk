# user_c_modules/wifi_pro/micropython.mk

MODULE = wifi_pro
SRC = wifi_pro.c

# Force compilation for S3 and SPIRAM/Opi if needed
CFLAGS += -DESP32S3 -DMP_CONFIG_ESP32_SPIRAM

# Ensure user module build can find core headers like py/buffer.h
CFLAGS += -I$(TOP)

PROJECT_DIR ?= $(CURDIR)
USER_C_MODULES += $(PROJECT_DIR)/user_c_modules/$(MODULE)
