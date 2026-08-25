cmake_minimum_required(VERSION 3.18.1)
project(foxitlic)

include(FetchContent)

set(ENABLE_TESTING OFF CACHE BOOL "" FORCE)
set(ENABLE_PROGRAMS OFF CACHE BOOL "" FORCE)
set(MBEDTLS_AS_SUBPROJECT ON CACHE BOOL "" FORCE)

FetchContent_Declare(
    mbedtls
    GIT_REPOSITORY https://github.com/Mbed-TLS/mbedtls.git
    GIT_TAG        v3.6.0
)
FetchContent_MakeAvailable(mbedtls)

add_library(foxitlic SHARED
    foxit_native_crypto.cpp
)

target_link_libraries(foxitlic
    mbedcrypto
    log
)

target_compile_options(foxitlic PRIVATE
    $<$<CONFIG:Release>:-fvisibility=hidden -fvisibility-inlines-hidden>
)
set_target_properties(foxitlic PROPERTIES
    LINK_FLAGS_RELEASE "-Wl,--exclude-libs,ALL -Wl,-s"
)
