cmake_minimum_required(VERSION 2.8.10)
project(sofa-pbrpc C CXX)

option(WITH_GLOG "With glog" OFF)
option(DEBUG "Print debug logs" OFF)
option(WITH_DEBUG_SYMBOLS "With debug symbols" ON)
option(WITH_THRIFT "With thrift framed protocol supported" OFF)
option(BUILD_UNIT_TESTS "Whether to build unit tests" OFF)
option(DOWNLOAD_GTEST "Download and build a fresh copy of \
                            googletest. Requires Internet access." ON)

# Enable MACOSX_RPATH. Run "cmake --help-policy CMP0042" for policy details.
if(POLICY CMP0042)
    cmake_policy(SET CMP0042 NEW)
endif()

#set(BRPC_VERSION 0.9.0)

#SET(CPACK_GENERATOR "DEB")
#SET(CPACK_DEBIAN_PACKAGE_MAINTAINER "brpc authors")
#INCLUDE(CPack)

# TODO OP check how this works on multiple configurations generators
# available configurations in multiple configurations enabled generators
set(CMAKE_CONFIGURATION_TYPES Debug Release)
#message("CMAKE_CFG_INTDIR = ${CMAKE_CFG_INTDIR}")

# 检查编译目录和源码是否为同一目录， 如果是则提示错误
if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")
    message(FATAL_ERROR "Do not build in-source.\nPlease remove CMakeCache.txt and the CMakeFiles/ directory.\nThen: mkdir build ; cd build ; cmake .. ; make")
endif()


if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release" CACHE STRING
  "Choose the type of build, options are: Debug Profile Release Asan Ubsan." FORCE)
endif(NOT CMAKE_BUILD_TYPE)

if( CMAKE_BUILD_TYPE STREQUAL "Release" )
    add_definitions(-DNODEBUG)
    add_definitions(-DRELEASE)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2 -Wall")
else()
    add_definitions(-DDEBUG)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ggdb")
    set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -ggdb")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ggdb -Wall")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -ggdb -Wall")
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    # require at least gcc 4.8
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 4.8)
        message(FATAL_ERROR "GCC is too old, please install a newer version supporting C++11")
    endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    # require at least clang 3.3
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 3.3)
        message(FATAL_ERROR "Clang is too old, please install a newer version supporting C++11")
    endif()
else()
    message(WARNING "You are using an unsupported compiler! Compilation has only been tested with Clang and GCC.")
endif()

set(WITH_GLOG_VAL "0")
if(WITH_GLOG)
    set(WITH_GLOG_VAL "1")
    set(BRPC_WITH_GLOG 1)
endif()

if(WITH_DEBUG_SYMBOLS)
    set(DEBUG_SYMBOL "-g")
	message("build for debug")
endif()

# for *.so
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/output/lib)
# for *.a
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/output/lib)
# for exe
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/output/bin)

include(GNUInstallDirs)

#configure_file(${PROJECT_SOURCE_DIR}/config.h.in ${PROJECT_SOURCE_DIR}/src/butil/config.h @ONLY)

set(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

find_package(GFLAGS REQUIRED)

execute_process(
    COMMAND bash -c "grep \"namespace [_A-Za-z0-9]\\+ {\" ${GFLAGS_INCLUDE_PATH}/gflags/gflags_declare.h | head -1 | awk '{print $2}' | tr -d '\n'"
    OUTPUT_VARIABLE GFLAGS_NS
)
if(${GFLAGS_NS} STREQUAL "GFLAGS_NAMESPACE")
    execute_process(
        COMMAND bash -c "grep \"#define GFLAGS_NAMESPACE [_A-Za-z0-9]\\+\" ${GFLAGS_INCLUDE_PATH}/gflags/gflags_declare.h | head -1 | awk '{print $3}' | tr -d '\n'"
        OUTPUT_VARIABLE GFLAGS_NS
    )
endif()

include_directories(
    ${PROJECT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_BINARY_DIR}/src
)

execute_process(
    COMMAND bash -c "git rev-parse --short HEAD | tr -d '\n'"
	OUTPUT_VARIABLE SOFA_PBRPC_REVISION
)

if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    include(CheckFunctionExists)
    CHECK_FUNCTION_EXISTS(clock_gettime HAVE_CLOCK_GETTIME)
    if(NOT HAVE_CLOCK_GETTIME)
        set(DEFINE_CLOCK_GETTIME "-DNO_CLOCK_GETTIME_IN_MAC")
    endif()
endif()

#-----------------------------------------------
# Customized macro switch:
#   SOFA_PBRPC_ENABLE_DETAILED_LOGGING : print current-time and thread-id in logging header
#   SOFA_PBRPC_ENABLE_FUNCTION_TRACE : print trace log when enter and leave function
#   SOFA_PBRPC_USE_SPINLOCK : use SpinLock as FastLock
#
#CXXFLAGS ?= -DSOFA_PBRPC_ENABLE_DETAILED_LOGGING


#set(CMAKE_CPP_FLAGS "${DEFINE_CLOCK_GETTIME} -DBRPC_WITH_GLOG=${WITH_GLOG_VAL} -DGFLAGS_NS=${GFLAGS_NS} -DHAVE_SNAPPY")
#set(CMAKE_CPP_FLAGS "${CMAKE_CPP_FLAGS} -DBTHREAD_USE_FAST_PTHREAD_MUTEX -D__const__= -D_GNU_SOURCE -DUSE_SYMBOLIZE -DNO_TCMALLOC -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS -D__STDC_CONSTANT_MACROS -DBRPC_REVISION=\\\"${BRPC_REVISION}\\\" -D__STRICT_ANSI__")
#set(CMAKE_CPP_FLAGS "${CMAKE_CPP_FLAGS} ${DEBUG_SYMBOL} ${THRIFT_CPP_FLAG}")
#set(CMAKE_CXX_FLAGS "${CMAKE_CPP_FLAGS} -O2 -pipe -Wall -W -fPIC -fstrict-aliasing -Wno-invalid-offsetof -Wno-unused-parameter -fno-omit-frame-pointer")
#set(CMAKE_C_FLAGS "${CMAKE_CPP_FLAGS} -O2 -pipe -Wall -W -fPIC -fstrict-aliasing -Wno-unused-parameter -fno-omit-frame-pointer")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2 -pipe -W -Wall -fPIC -D_GNU_SOURCE -D__STDC_LIMIT_MACROS -DHAVE_SNAPPY")

macro(use_cxx11)
if(CMAKE_VERSION VERSION_LESS "3.1.3")
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
    endif()
    if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
    endif()
else()
    set(CMAKE_CXX_STANDARD 11)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()
endmacro(use_cxx11)

use_cxx11()

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    #required by butil/crc32.cc to boost performance for 10x
    if(NOT (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 4.4))
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -msse4 -msse4.2")
    endif()
    if(NOT (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 7.0))
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-aligned-new")
    endif()
endif()

include(FindProtobuf)
include(FindThreads)

#find_path(LEVELDB_INCLUDE_PATH NAMES leveldb/db.h)
#find_library(LEVELDB_LIB NAMES leveldb)
#if ((NOT LEVELDB_INCLUDE_PATH) OR (NOT LEVELDB_LIB))
#    message(FATAL_ERROR "Fail to find leveldb")
#endif()

if(WITH_GLOG)
    find_path(GLOG_INCLUDE_PATH NAMES glog/logging.h)
    find_library(GLOG_LIB NAMES glog)
    if((NOT GLOG_INCLUDE_PATH) OR (NOT GLOG_LIB))
        message(FATAL_ERROR "Fail to find glog")
    endif()
    include_directories(${GLOG_INCLUDE_PATH})
endif()

find_library(PROTOC_LIB NAMES protoc)
if(NOT PROTOC_LIB)
    message(FATAL_ERROR "Fail to find protoc lib")
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(OPENSSL_ROOT_DIR
        "/usr/local/opt/openssl"    # Homebrew installed OpenSSL
        )
endif()

include(FindOpenSSL)

include_directories(
        ${GFLAGS_INCLUDE_PATH}
        ${PROTOBUF_INCLUDE_DIRS}
        ${LEVELDB_INCLUDE_PATH}
        ${OPENSSL_INCLUDE_DIR}
        )

set(DYNAMIC_LIB
    ${GFLAGS_LIBRARY}
    ${PROTOBUF_LIBRARIES}
    ${LEVELDB_LIB}
    ${PROTOC_LIB}
    ${CMAKE_THREAD_LIBS_INIT}
    ${THRIFT_LIB}
    ${THRIFTNB_LIB}
    ${OPENSSL_LIBRARIES}
    ${OPENSSL_CRYPTO_LIBRARY}
    dl
    z)
set(BRPC_PRIVATE_LIBS "-lgflags -lprotobuf -lleveldb -lprotoc -lssl -lcrypto -ldl -lz")

if(WITH_GLOG)
    set(DYNAMIC_LIB ${DYNAMIC_LIB} ${GLOG_LIB})
    set(BRPC_PRIVATE_LIBS "${BRPC_PRIVATE_LIBS} -lglog")
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(DYNAMIC_LIB ${DYNAMIC_LIB} rt)
    set(BRPC_PRIVATE_LIBS "${BRPC_PRIVATE_LIBS} -lrt")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(DYNAMIC_LIB ${DYNAMIC_LIB}
        pthread
        "-framework CoreFoundation"
        "-framework CoreGraphics"
        "-framework CoreData"
        "-framework CoreText"
        "-framework Security"
        "-framework Foundation"
        "-Wl,-U,_MallocExtension_ReleaseFreeMemory"
        "-Wl,-U,_ProfilerStart"
        "-Wl,-U,_ProfilerStop")
endif()

# the reason why not using file(GLOB_RECURSE...) is that we want to
# include different files on different platforms.
#include(CompileProto)

#add_subdirectory(src/sofa/pbrpc)
include(sofa.pbrpc.cmake)

#if(BUILD_UNIT_TESTS)
#    enable_testing()
#    add_subdirectory(test)
#endif()
#add_subdirectory(tools)

#file(COPY ${CMAKE_CURRENT_BINARY_DIR}/sofa/pbrpc/
#        DESTINATION ${PROJECT_BINARY_DIR}/output/include/sofa/pbrpc/
#        FILES_MATCHING
#        PATTERN "*.h"
#        PATTERN "*.hpp"
#        )
#file(COPY ${PROJECT_SOURCE_DIR}/sofa/pbrpc/smart_ptr/
#        DESTINATION ${PROJECT_BINARY_DIR}/output/include/sofa/pbrpc/smart_ptr/
#        FILES_MATCHING
#        PATTERN "*.h"
#        PATTERN "*.hpp"
#        )
#file(COPY ${PROJECT_SOURCE_DIR}/sofa/pbrpc/smart_ptr/detail/
#        DESTINATION ${PROJECT_BINARY_DIR}/output/include/sofa/pbrpc/smart_ptr/detail/
#        FILES_MATCHING
#        PATTERN "*.h"
#        PATTERN "*.hpp"
#        )


	install(DIRECTORY ${PROJECT_SOURCE_DIR}/src/sofa/pbrpc/
	    DESTINATION  ${PROJECT_BINARY_DIR}/output/include/sofa/pbrpc/
	    FILES_MATCHING
	    PATTERN "*.h"
	    PATTERN "*.hpp"
	    )

# Install pkgconfig
#configure_file(cmake/brpc.pc.in ${PROJECT_BINARY_DIR}/brpc.pc @ONLY)
#install(FILES ${PROJECT_BINARY_DIR}/brpc.pc DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig)
