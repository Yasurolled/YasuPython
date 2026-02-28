# micropython.cmake for wifi_pro module
# create an INTERFACE library containing the module sources and headers
add_library(usermod_wifi_pro INTERFACE)

target_sources(usermod_wifi_pro INTERFACE
    ${CMAKE_CURRENT_LIST_DIR}/wifi_pro.c
)

target_include_directories(usermod_wifi_pro INTERFACE
    ${CMAKE_CURRENT_LIST_DIR}
)

# link to the global usermod target so that the files are added to the build
# (usermod is defined by py/usermod.cmake in the main tree)
target_link_libraries(usermod INTERFACE usermod_wifi_pro)
