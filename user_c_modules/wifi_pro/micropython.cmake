add_library(usermod_wifi_pro INTERFACE)

target_sources(usermod_wifi_pro INTERFACE
    ${CMAKE_CURRENT_LIST_DIR}/wifi_pro.c
)

target_include_directories(usermod_wifi_pro INTERFACE
    ${CMAKE_CURRENT_LIST_DIR}
)

target_link_libraries(usermod INTERFACE usermod_wifi_pro)