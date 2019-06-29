include_directories(${PROJECT_SOURCE_DIR})
include_directories(${PROJECT_BINARY_DIR})

include_directories(${PROJECT_SOURCE_DIR}/src)
include_directories(${PROJECT_BINARY_DIR}/src)

include_directories(${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${CMAKE_CURRENT_BINARY_DIR})

message("path ${PROJECT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}")

LINK_DIRECTORIES(${PROJECT_BINARY_DIR})
LINK_DIRECTORIES(${CMAKE_CURRENT_BINARY_DIR})

STRING( REGEX REPLACE ".*/(.*)" "\\1" CURRENT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src )

set(PROTO_FILE_PATH "${PROJECT_SOURCE_DIR}/src/sofa/pbrpc")
set(PROTOBUF_SRC_ROOT_FOLDER ${PROJECT_SOURCE_DIR}/src)
set(PROTOBUF_IMPORT_DIRS ${PROJECT_SOURCE_DIR}/src)
file(GLOB PROTO_PB_FILES ${CMAKE_CURRENT_SOURCE_DIR}/src/sofa/pbrpc/*.proto)
#file(GLOB_RECURSE PROTO_PB_FILES ${CMAKE_CURRENT_SOURCE_DIR} *.proto)
#set(PROTO_PB_FILES ${PROTO_FILE_PATH}/rpc_option.proto ${PROTO_FILE_PATH}/rpc_meta.proto ${PROTO_FILE_PATH}/builtin_service.proto)
message("proto files: ${PROTO_PB_FILES}")
#PROTOBUF_GENERATE_CPP(PROTO_SRCS PROTO_HDRS ${PROTO_PB_FILES})
FOREACH(proto_file ${PROTO_PB_FILES})
    #FILE(TO_NATIVE_PATH ${proto} proto_native)
    EXECUTE_PROCESS(COMMAND ${PROTOBUF_PROTOC_EXECUTABLE} --proto_path=${PROTOBUF_IMPORT_DIRS} --cpp_out=${CMAKE_CURRENT_SOURCE_DIR}/src ${proto_file}
    RESULT_VARIABLE rv)
    # Optional, but that can show the user if something have gone wrong with the proto generation 
    IF(${rv})
         MESSAGE("Generation of data model returned ${rv} for proto ${proto_native}")
    ENDIF()
	message("generation success for ${proto_file}")
ENDFOREACH(proto_file)
## List generated sources files
#FILE(GLOB PROTO_HDRS "${CMAKE_CURRENT_SOURCE_DIR}/src/sofa/pbrpc/*.pb.h")
#FILE(GLOB PROTO_SRCS "${CMAKE_CURRENT_SOURCE_DIR}/src/sofa/pbrpc/*.pb.cc")
#message("pb files: ${PROTO_HDRS} ${PROTO_SRCS}")

#aux_source_directory(. DIR_SRCS)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/src/sofa/pbrpc DIR_SRCS)
#message("source files: ${DIR_SRCS}")
set(LIB_NAME sofa-pbrpc)
#add_library(${LIB_NAME} STATIC ${PROTO_SRCS} ${PROTO_HDRS} ${DIR_SRCS})
add_library(${LIB_NAME} STATIC ${DIR_SRCS})
#add_dependencies(${LIB_NAME} butil)
add_library(${LIB_NAME}-dy SHARED ${DIR_SRCS})
target_link_libraries(${LIB_NAME}-dy rt z protobuf snappy pthread)
unset(LIB_NAME)
