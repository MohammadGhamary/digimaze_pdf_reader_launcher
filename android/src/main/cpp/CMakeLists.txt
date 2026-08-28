cmake_minimum_required(VERSION 3.11)
project("digimaze_param_decryptor")

include(FetchContent)

find_library(log-lib log)

set(ENABLE_PROGRAMS OFF CACHE BOOL "" FORCE)
set(ENABLE_TESTING OFF CACHE BOOL "" FORCE)
set(MBEDTLS_FATAL_WARNINGS OFF CACHE BOOL "" FORCE)
set(ENABLE_ZLIB_SUPPORT OFF CACHE BOOL "" FORCE)

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/mbedtls/CMakeLists.txt")
    add_subdirectory(third_party/mbedtls EXCLUDE_FROM_ALL)
    set(MBEDTLS_INC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/mbedtls/include")
else()
    message(STATUS "mbedtls directory not found locally. Fetching automatically from GitHub...")
    FetchContent_Declare(
            mbedtls
            GIT_REPOSITORY https://github.com/Mbed-TLS/mbedtls.git
            GIT_TAG        v3.6.0
            GIT_SUBMODULES_RECURSE TRUE
    )
    FetchContent_MakeAvailable(mbedtls)
    set(MBEDTLS_INC_DIR "${mbedtls_SOURCE_DIR}/include")
endif()
# -----------------------------------------------------------------------------

add_library(
        paramdecryptor
        SHARED
        jni_bridge.cpp
        param_decryptor.cpp
        crypto_provider.cpp
)

target_compile_features(paramdecryptor PRIVATE cxx_std_17)

target_include_directories(
        paramdecryptor
        PRIVATE
        ${MBEDTLS_INC_DIR}
)

target_link_libraries(
        paramdecryptor
        ${log-lib}
        mbedcrypto
)