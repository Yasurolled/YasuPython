cmake_minimum_required(VERSION 3.22)
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(asdasdasdasdasdasdasds)
idf_component_register(SRCS "main.c" "raw_blue.c" "raw_wifi.c"
                    INCLUDE_DIRS ".")
