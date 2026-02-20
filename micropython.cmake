# Yasu, değişkeni set() fonksiyonu ile tanımlıyoruz
set(USERMOD_DIR ${CMAKE_CURRENT_LIST_DIR})

# C dosyasını MicroPython kullanıcı modüllerine dahil ediyoruz
target_sources(usermod INTERFACE "${USERMOD_DIR}/esp_wifi_80211_tx.c")

# Başlık dosyalarının (Header) bulunabilmesi için dizini ekliyoruz
target_include_directories(usermod INTERFACE "${USERMOD_DIR}")
