cmake_minimum_required(VERSION 3.28)

project (dep_codecs)

# Forward toolchain and platform variables to external projects
set(FORWARD_ARGS)
if(CMAKE_SYSTEM_NAME)
    list(APPEND FORWARD_ARGS -DCMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME})
endif()
if(CMAKE_OSX_SYSROOT)
    list(APPEND FORWARD_ARGS -DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT})
endif()
if(CMAKE_OSX_ARCHITECTURES)
    list(APPEND FORWARD_ARGS -DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES})
endif()
if(CMAKE_TOOLCHAIN_FILE)
    list(APPEND FORWARD_ARGS -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})
endif()

# Fetch opus library (Royalty-Free)
include(ExternalProject)
ExternalProject_Add(
    dep_opus
    URL https://downloads.xiph.org/releases/opus/opus-1.4.tar.gz
    CMAKE_ARGS ${FORWARD_ARGS} -DBUILD_SHARED_LIBS=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${DEP_CODECS_DIR} -DCMAKE_POLICY_VERSION_MINIMUM=3.5
)

# Fetch flac library (Royalty-Free)
include(ExternalProject)
ExternalProject_Add(
    dep_flac
    URL https://downloads.xiph.org/releases/flac/flac-1.4.2.tar.xz
    CMAKE_ARGS ${FORWARD_ARGS} -DBUILD_SHARED_LIBS=OFF -DWITH_OGG=OFF -DBUILD_CXXLIBS=OFF -DINSTALL_MANPAGES=OFF -DBUILD_PROGRAMS=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${DEP_CODECS_DIR} -DCMAKE_C_FLAGS=-D_FILE_OFFSET_BITS=64
)

# Fetch fdk-aac(2.0.3) library ONLY if ENABLE_AAC_CODEC_UNLICENSED is ON
if (ENABLE_AAC_CODEC_UNLICENSED)
    message(STATUS "Fetching and building FDK-AAC (ENABLE_AAC_CODEC_UNLICENSED=ON)")
    include(ExternalProject)
    ExternalProject_Add(
        dep_aac
        GIT_REPOSITORY https://github.com/mstorsjo/fdk-aac.git
        GIT_TAG 716f4394641d53f0d79c9ddac3fa93b03a49f278
        PATCH_COMMAND ${CMAKE_COMMAND} -E make_directory <SOURCE_DIR>/libSBRdec/include/log && ${CMAKE_COMMAND} -E echo "void android_errorWriteLog(int i, const char *string){}" > <SOURCE_DIR>/libSBRdec/include/log/log.h
        CMAKE_ARGS ${FORWARD_ARGS} -DBUILD_SHARED_LIBS=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${DEP_CODECS_DIR}
    )
else()
    message(STATUS "Excluding FDK-AAC fetch and build (ENABLE_AAC_CODEC_UNLICENSED=OFF)")
endif()
