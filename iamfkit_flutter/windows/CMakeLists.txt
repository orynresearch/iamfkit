# Windows CMakeLists.txt for iamfkit Flutter plugin
cmake_minimum_required(VERSION 3.14)
project(iamfkit VERSION 0.1.0 LANGUAGES C)

add_library(iamfkit SHARED
  "${CMAKE_CURRENT_SOURCE_DIR}/../src/iamfkit_wrapper.c"
)

set_target_properties(iamfkit PROPERTIES
  PUBLIC_HEADER "${CMAKE_CURRENT_SOURCE_DIR}/../src/iamfkit_wrapper.h"
  OUTPUT_NAME "iamfkit"
)

target_compile_definitions(iamfkit PUBLIC DART_SHARED_LIB)

set(LIBIAMF_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(LIBIAMF_DLL "${LIBIAMF_DIR}/iamf.dll")
set(LIBIAMF_LIB "${LIBIAMF_DIR}/iamf.lib")

if(NOT EXISTS "${LIBIAMF_DLL}")
  message(FATAL_ERROR
    "iamf.dll not found at ${LIBIAMF_DLL}.\n"
    "Run scripts\\build_windows.bat to build it.")
endif()

target_include_directories(iamfkit PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  "${CMAKE_CURRENT_SOURCE_DIR}/../src"
)

if(EXISTS "${LIBIAMF_LIB}")
  target_link_libraries(iamfkit PRIVATE "${LIBIAMF_LIB}")
else()
  target_link_options(iamfkit PRIVATE "/DELAYLOAD:iamf.dll")
endif()

install(FILES "${LIBIAMF_DLL}" DESTINATION "${CMAKE_INSTALL_PREFIX}")
