cmake_minimum_required(VERSION 3.28)

project (iamf)
message(STATUS "Start build libiamf")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3")
if(NOT MSVC)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Werror=unused-variable")
endif()
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(DEP_CODECS_DIR        "${PROJECT_SOURCE_DIR}/dep_codecs")
set(DEP_EXTERNAL_DIR      "${PROJECT_SOURCE_DIR}/dep_external")

option(IAMF_BUILD_SHARED_LIB "Build shared library" ON)
option(IAMF_ENABLE_BINAURALIZER "Enable binaural rendering"  ON)
option(ENABLE_BUILD_CODECS "Build royalty-free codecs (Opus & FLAC)" ON)
option(ENABLE_AAC_CODEC_UNLICENSED "Build non-free FDK-AAC codec" OFF)
option(IAMF_TEST_TOOL "IAMF test tool" OFF)
option(SUPPORT_VERIFIER "Output vlogging file" OFF)

if (SUPPORT_VERIFIER)
    message(STATUS "Output vlogging file")
    add_definitions(-DSUPPORT_VERIFIER=1)
endif()

if (CMAKE_BUILD_TYPE)
    string(TOLOWER ${CMAKE_BUILD_TYPE} BUILD_TYPE)
    if ("${BUILD_TYPE}" STREQUAL "debug")
        add_definitions(-DIA_DBG)
        message(STATUS "Debug mode")
    endif()
endif()

if (ENABLE_BUILD_CODECS)
    add_subdirectory(dep_codecs)
    add_definitions(-DCONFIG_OPUS_CODEC -DCONFIG_FLAC_CODEC)
    if(MSVC)
        add_definitions(-DFLAC__NO_DLL)
    endif()

    if (ENABLE_AAC_CODEC_UNLICENSED)
        message(STATUS "ENABLE_AAC_CODEC_UNLICENSED is ON: Including FDK-AAC codec")
        add_definitions(-DCONFIG_AAC_CODEC)
    else()
        message(STATUS "ENABLE_AAC_CODEC_UNLICENSED is OFF: AAC codec excluded for licensing compliance")
    endif()
else()
    unset(find_opus CACHE)
    find_library(find_opus NAMES opus PATHS ${DEP_CODECS_DIR}/lib NO_DEFAULT_PATH)
    if(${find_opus} STREQUAL "find_opus-NOTFOUND")
        message(STATUS "The opus library was not found")
    else()
        add_definitions(-DCONFIG_OPUS_CODEC)
    endif()

    if (ENABLE_AAC_CODEC_UNLICENSED)
        unset(find_aac CACHE)
        find_library(find_aac NAMES fdk-aac PATHS ${DEP_CODECS_DIR}/lib NO_DEFAULT_PATH)
        if(${find_aac} STREQUAL "find_aac-NOTFOUND")
            message(STATUS "The aac library was not found")
        else()
            add_definitions(-DCONFIG_AAC_CODEC)
        endif()
    endif()

    unset(find_flac CACHE)
    find_library(find_flac NAMES FLAC PATHS ${DEP_CODECS_DIR}/lib NO_DEFAULT_PATH)
    if(${find_flac} STREQUAL "find_flac-NOTFOUND")
        message(STATUS "The flac library was not found")
    else()
        add_definitions(-DCONFIG_FLAC_CODEC)
        if(MSVC)
            add_definitions(-DFLAC__NO_DLL)
        endif()
    endif()
endif()

if (IAMF_ENABLE_BINAURALIZER)
    set(OAR_ENABLE_BINAURALIZER ON)
else()
    set(OAR_ENABLE_BINAURALIZER OFF)
endif()
set(OAR_BUILD_SHARED_LIBRARY OFF)
add_subdirectory(dep_external/src/oar EXCLUDE_FROM_ALL)

file(GLOB_RECURSE sources CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/dep_external/src/wav/*.c")

include_directories(
    include
    ${DEP_CODECS_DIR}/include
    ${DEP_EXTERNAL_DIR}/include
    ${DEP_EXTERNAL_DIR}/src/oar/include
    ${DEP_EXTERNAL_DIR}/src/oar/src/common
    ${PROJECT_SOURCE_DIR}/src/iamf_dec
    ${PROJECT_SOURCE_DIR}/src/iamf_dec/codec
    ${PROJECT_SOURCE_DIR}/src/iamf_dec/codec/opus
    ${PROJECT_SOURCE_DIR}/src/iamf_dec/codec/flac
    ${PROJECT_SOURCE_DIR}/src/iamf_dec/common
    ${PROJECT_SOURCE_DIR}/src/iamf_dec/obu
)

if (ENABLE_AAC_CODEC_UNLICENSED)
    include_directories(${PROJECT_SOURCE_DIR}/src/iamf_dec/codec/aac)
endif()

link_directories (
    ${DEP_CODECS_DIR}/lib
)

if(IAMF_BUILD_SHARED_LIB)
    add_library(${PROJECT_NAME} SHARED ${sources})
else()
    add_library(${PROJECT_NAME} STATIC ${sources})
endif()

if (ENABLE_BUILD_CODECS)
    if (ENABLE_AAC_CODEC_UNLICENSED)
        add_dependencies(${PROJECT_NAME} dep_opus dep_aac dep_flac oar)
        target_link_libraries (${PROJECT_NAME} opus fdk-aac FLAC oar)
    else()
        add_dependencies(${PROJECT_NAME} dep_opus dep_flac oar)
        target_link_libraries (${PROJECT_NAME} opus FLAC oar)
    endif()
else()
    if(NOT ${find_opus} STREQUAL "find_opus-NOTFOUND")
        target_link_libraries (${PROJECT_NAME} opus)
    endif()
    if(NOT ${find_flac} STREQUAL "find_flac-NOTFOUND")
        target_link_libraries (${PROJECT_NAME} FLAC)
    endif()
    if(ENABLE_AAC_CODEC_UNLICENSED AND NOT ${find_aac} STREQUAL "find_aac-NOTFOUND")
        target_link_libraries (${PROJECT_NAME} fdk-aac)
    endif()
    target_link_libraries (${PROJECT_NAME} oar)
endif()
