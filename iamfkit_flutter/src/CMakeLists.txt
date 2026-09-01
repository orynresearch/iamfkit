# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(eclipsa_iamf_decoder_library VERSION 0.0.1 LANGUAGES C)

add_library(eclipsa_iamf_decoder SHARED
  "eclipsa_iamf_decoder.c"
)

set_target_properties(eclipsa_iamf_decoder PROPERTIES
  PUBLIC_HEADER eclipsa_iamf_decoder.h
  OUTPUT_NAME "eclipsa_iamf_decoder"
)

target_compile_definitions(eclipsa_iamf_decoder PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(eclipsa_iamf_decoder PRIVATE "-Wl,-z,max-page-size=16384")
endif()
