# Linux CMakeLists.txt for iamfkit Flutter plugin
cmake_minimum_required(VERSION 3.10)
project(iamfkit VERSION 0.1.0 LANGUAGES C)

add_library(iamfkit SHARED
  "${CMAKE_CURRENT_SOURCE_DIR}/../src/iamfkit_wrapper.c"
)

set_target_properties(iamfkit PROPERTIES
  PUBLIC_HEADER "${CMAKE_CURRENT_SOURCE_DIR}/../src/iamfkit_wrapper.h"
  OUTPUT_NAME "iamfkit"
)

target_compile_definitions(iamfkit PUBLIC DART_SHARED_LIB)

set(LIBIAMF_SO "${CMAKE_CURRENT_SOURCE_DIR}/libiamf.so")

if(NOT EXISTS "${LIBIAMF_SO}")
  message(FATAL_ERROR
    "libiamf.so not found at ${LIBIAMF_SO}.\n"
    "Run scripts/build_linux.sh from the plugin root to build it.")
endif()

target_include_directories(iamfkit PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  "${CMAKE_CURRENT_SOURCE_DIR}/../src"
)

target_link_libraries(iamfkit PRIVATE
  "${LIBIAMF_SO}"
  m
)

install(FILES "${LIBIAMF_SO}" DESTINATION "${CMAKE_INSTALL_PREFIX}/lib")
