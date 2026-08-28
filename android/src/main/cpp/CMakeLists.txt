cmake_minimum_required(VERSION 3.10.2)
project("digimaze_param_decryptor")

find_library(log-lib log)

set(ENABLE_PROGRAMS OFF CACHE BOOL "" FORCE)
set(ENABLE_TESTING OFF CACHE BOOL "" FORCE)
set(MBEDTLS_FATAL_WARNINGS OFF CACHE BOOL "" FORCE)
set(ENABLE_ZLIB_SUPPORT OFF CACHE BOOL "" FORCE)


find_package(Git QUIET)
if(GIT_FOUND AND NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/mbedtls/framework/CMakeLists.txt")
    message(STATUS "mbedtls framework submodules not found. Running git submodule update...")
    execute_process(
            COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
            RESULT_VARIABLE GIT_SUBMOD_RESULT
    )
    if(NOT GIT_SUBMOD_RESULT EQUAL "0")
        message(FATAL_ERROR "git submodule update failed with error code ${GIT_SUBMOD_RESULT}")
    endif()
endif()

add_subdirectory(third_party/mbedtls EXCLUDE_FROM_ALL)

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
        third_party/mbedtls/include
)

target_link_libraries(
        paramdecryptor
        ${log-lib}
        mbedcrypto
)