if(APPLE AND NOT DEFINED ENV{MACOSX_DEPLOYMENT_TARGET} AND NOT DEFINED ENV{SDKROOT})
  set(CMAKE_OSX_DEPLOYMENT_TARGET ${CMAKE_SYSTEM_VERSION})
endif()

cmake_minimum_required(VERSION 3.6.3)
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/CMake;${CMAKE_MODULE_PATH}")
include(Utilities)
project(KinesisVideoProducerCpp)

set(CMAKE_CXX_STANDARD 11)

# Build setting
set(CMAKE_ARGS
        -DCMAKE_FIND_ROOT_PATH=${CMAKE_FIND_ROOT_PATH}
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
        -DANDROID_TOOLCHAIN=clang
        -DANDROID_NDK_ROOT=${ANDROID_NDK_ROOT}
        -DANDROID_ABI=${ANDROID_ABI}
        -DANDROID_NDK=${ANDROID_NDK}
        -DANDROID_PLATFORM=${ANDROID_PLATFORM}
        -DANDROID_API_LEVEL=${ANDROID_API_LEVEL}
        -DANDROID_ARCH=${ANDROID_ARCH}
        -DCMAKE_ANDROID_ARCH_ABI=${CMAKE_ANDROID_ARCH_ABI}
        -DCMAKE_ANDROID_NDK=${CMAKE_ANDROID_NDK}
        -DCMAKE_SYSTEM_NAME=Android
        -DCMAKE_SYSTEM_VERSION=${CMAKE_SYSTEM_VERSION}
        -DCMAKE_BUILD_TYPE=Release)

message ("kvssink: CMAKE_FIND_ROOT_PATH=${CMAKE_FIND_ROOT_PATH}")

# User Flags
option(BUILD_GSTREAMER_PLUGIN "Build kvssink GStreamer plugin" OFF)
option(BUILD_JNI "Build C++ wrapper for JNI to expose the functionality to Java/Android" OFF)
option(BUILD_STATIC "Build with static linkage" OFF)
option(ADD_MUCLIBC "Add -muclibc c flag" OFF)
option(BUILD_DEPENDENCIES "Whether or not to build depending libraries from source" ON)
option(BUILD_OPENSSL_PLATFORM "If buildng OpenSSL what is the target platform" OFF)
option(BUILD_LOG4CPLUS_HOST "Specify host-name for log4cplus for cross-compilation" OFF)


# Developer Flags
option(BUILD_TEST "Build the testing tree" OFF)
option(CODE_COVERAGE "Enable coverage reporting" OFF)
option(COMPILER_WARNINGS "Enable all compiler warnings" OFF)
option(ADDRESS_SANITIZER "Build with AddressSanitize." OFF)
option(MEMORY_SANITIZER "Build with MemorySanitizer" OFF)
option(THREAD_SANITIZER "Build with ThreadSanitizer" OFF)
option(UNDEFINED_BEHAVIOR_SANITIZER "Build with UndefinedBehaviorSanitizer" OFF)

set(CMAKE_MACOSX_RPATH TRUE)
get_filename_component(ROOT "${CMAKE_CURRENT_SOURCE_DIR}" ABSOLUTE)

# static settings
if(BUILD_STATIC)
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")
  set(LINKAGE STATIC)
elseif(WIN32)
  set(LINKAGE STATIC)
else()
  set(LINKAGE SHARED)
endif()

set(KINESIS_VIDEO_PRODUCER_CPP_SRC ${CMAKE_CURRENT_SOURCE_DIR})
set(KINESIS_VIDEO_OPEN_SOURCE_SRC ${CMAKE_CURRENT_SOURCE_DIR}/open-source)

message(STATUS "Kinesis Video Cpp Producer path is ${KINESIS_VIDEO_PRODUCER_CPP_SRC}")
message(STATUS "dependencies install path is ${KINESIS_VIDEO_OPEN_SOURCE_SRC}")

if(NOT EXISTS ${KINESIS_VIDEO_PRODUCER_CPP_SRC})
  message(FATAL_ERROR "KINESIS_VIDEO_PRODUCER_CPP_SRC ${KINESIS_VIDEO_PRODUCER_CPP_SRC} does not exist")
endif()

# pass ca cert location to sdk
add_definitions(-DKVS_CA_CERT_PATH="${CMAKE_CURRENT_SOURCE_DIR}/certs/cert.pem")
add_definitions(-DCMAKE_DETECTED_CACERT_PATH)


if(BUILD_DEPENDENCIES)
  if(NOT EXISTS ${KINESIS_VIDEO_OPEN_SOURCE_SRC})
    file(MAKE_DIRECTORY ${KINESIS_VIDEO_OPEN_SOURCE_SRC}/local)
  endif()

  if (NOT OPEN_SRC_INSTALL_PREFIX)
    set(OPEN_SRC_INSTALL_PREFIX ${KINESIS_VIDEO_OPEN_SOURCE_SRC}/local)
    set(ENV{PKG_CONFIG_PATH}
          "$ENV{PKG_CONFIG_PATH}:${OPEN_SRC_INSTALL_PREFIX}/lib/pkgconfig")
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${OPEN_SRC_INSTALL_PREFIX})
    set(ENV{PATH} "$ENV{PATH}:${OPEN_SRC_INSTALL_PREFIX}/bin")
  endif()

  message("CMAKE_ARGS = ${CMAKE_ARGS}")
  message(STATUS "Begin building dependencies.")

  if (NOT WIN32)
    build_dependency(autoconf)
    build_dependency(automake)
  endif()

  message(STATUS "ANDROID_ABI = ${ANDROID_ABI}")

  if(BUILD_LOG4CPLUS_HOST)
    set(BUILD_ARGS -DBUILD_LOG4CPLUS_HOST=${BUILD_LOG4CPLUS_HOST})
    build_dependency(log4cplus ${CMAKE_ARGS}  ${BUILD_ARGS})
  else()
    build_dependency(log4cplus ${CMAKE_ARGS})
  endif()

  message(STATUS "Finished building dependencies.")
endif()

set(BUILD_COMMON_LWS
    FALSE
    CACHE BOOL "Build ProducerC without LWS Support" FORCE)
set(BUILD_COMMON_CURL
    TRUE
    CACHE BOOL "Build ProducerC with CURL Support" FORCE)
set(DEPENDENCY_DOWNLOAD_PATH ${CMAKE_CURRENT_SOURCE_DIR}/dependency)
if(NOT EXISTS ${DEPENDENCY_DOWNLOAD_PATH})
  file(MAKE_DIRECTORY ${DEPENDENCY_DOWNLOAD_PATH})
endif()
fetch_repo(kvscproducer ${CMAKE_ARGS})
add_subdirectory(${DEPENDENCY_DOWNLOAD_PATH}/libkvscproducer/kvscproducer-src EXCLUDE_FROM_ALL)

message(STATUS "#####################################################################")


############# find dependent libraries ############

find_package(Threads)
find_package(PkgConfig REQUIRED)

if (OPEN_SRC_INSTALL_PREFIX)
  find_package(CURL REQUIRED PATHS ${OPEN_SRC_INSTALL_PREFIX})
else()
  find_package(CURL REQUIRED)
endif()

set(OPEN_SRC_INCLUDE_DIRS ${OPEN_SRC_INCLUDE_DIRS} ${CURL_INCLUDE_DIRS})
link_directories(${CURL_LIBRARY_DIRS})

if (WIN32)
  find_package(Log4cplus
    NAMES log4cplus REQUIRED
    PATHS ${OPEN_SRC_INSTALL_PREFIX}/lib)
  SET(Log4cplus "log4cplus::log4cplus")
else()
  find_package(Log4cplus REQUIRED)
  include_directories(${LOG4CPLUS_INCLUDE_DIR})
  set(Log4cplus ${LOG4CPLUS_LIBRARIES})
endif()

if (WIN32)
  set(PKG_CONFIG_EXECUTABLE "C:\\gstreamer\\1.0\\x86_64\\bin\\pkg-config.exe")
endif()

#message(FATAL_ERROR "======= STOP for now =======")

############# Enable Sanitizers ############
if(${CMAKE_C_COMPILER_ID} MATCHES "GNU|Clang")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")

  if(ADD_MUCLIBC)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -muclibc")
  endif()

  if(CODE_COVERAGE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O0 -g -fprofile-arcs -ftest-coverage")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
  endif()

  if(ADDRESS_SANITIZER)
    enableSanitizer("address")
  endif()
  if(MEMORY_SANITIZER)
    enableSanitizer("memory")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize-memory-track-origins")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize-memory-track-origins")
  endif()
  if(THREAD_SANITIZER)
    enableSanitizer("thread")
  endif()
  if(UNDEFINED_BEHAVIOR_SANITIZER)
    enableSanitizer("undefined")
  endif()
endif()

if(MSVC)
  add_definitions(-D_CRT_SECURE_NO_WARNINGS -D_CRT_NONSTDC_NO_WARNINGS -D_SILENCE_TR1_NAMESPACE_DEPRECATION_WARNING)
endif()

############# Build Targets ############
file(GLOB PRODUCER_CPP_SOURCE_FILES "src/*.cpp" "src/common/*.cpp" "src/credential-providers/*.cpp")
file(GLOB GST_PLUGIN_SOURCE_FILES "src/gstreamer/*.cpp" "src/gstreamer/Util/*.cpp")
file(GLOB_RECURSE JNI_SOURCE_FILES "src/JNI/*.cpp")
file(GLOB PIC_HEADERS "${pic_project_SOURCE_DIR}/src/*/include")

include_directories(${PIC_HEADERS})
include_directories(${KinesisVideoProducerC_SOURCE_DIR}/src/include)
include_directories(${OPEN_SRC_INCLUDE_DIRS})
include_directories(${KINESIS_VIDEO_OPEN_SOURCE_SRC}/include)
include_directories(${KINESIS_VIDEO_PRODUCER_CPP_SRC}/src)
include_directories(${KINESIS_VIDEO_PRODUCER_CPP_SRC}/src/credential-providers)
include_directories(${KINESIS_VIDEO_PRODUCER_CPP_SRC}/src/common)
include_directories(${KINESIS_VIDEO_PRODUCER_CPP_SRC}/src/JNI/include)

add_library(KinesisVideoProducer ${LINKAGE} ${PRODUCER_CPP_SOURCE_FILES})
target_link_libraries(
  KinesisVideoProducer
  PUBLIC kvsCommonCurl
         cproducer
         ${Log4cplus}
         ${LIBCURL_LIBRARIES})

if(BUILD_JNI)
  find_package(JNI REQUIRED)
  include_directories(${JNI_INCLUDE_DIRS})

  add_library(KinesisVideoProducerJNI SHARED ${JNI_HEADERS} ${JNI_SOURCE_FILES})
  target_link_libraries(KinesisVideoProducerJNI kvspic)
endif()


if(BUILD_GSTREAMER_PLUGIN)
  #set(GST_ROOT "/root/develop/test3/gstreamer-1.0/armv7")
  pkg_check_modules(GST_APP REQUIRED gstreamer-app-1.0)

  set(GST_APP_INCLUDE_DIRS "${GST_APP_INCLUDE_DIRS};/home/jan/devel/gstreamer/cerbero/build/sources/android_universal/${GST_ABI}/include/gstreamer-1.0")
  set(GST_APP_INCLUDE_DIRS "${GST_APP_INCLUDE_DIRS};/home/jan/devel/gstreamer/cerbero/build/sources/android_universal/${GST_ABI}/include/glib-2.0")
  set(GST_APP_INCLUDE_DIRS "${GST_APP_INCLUDE_DIRS};/home/jan/devel/gstreamer/cerbero/build/sources/android_universal/${GST_ABI}/lib/glib-2.0/include")

  #/home/jan/devel/gstreamer/cerbero/build/sources/android_universal/${GST_ABI}/lib/gstreamer-1.0
  #set(GST_APP_LIBRARY_DIRS "${GST_APP_LIBRARY_DIRS};/home/jan/devel/gstreamer/cerbero/build/sources/android_universal/${GST_ABI}/lib/gstreamer-1.0")

  message("GST_APP_INCLUDE_DIRS = ${GST_APP_INCLUDE_DIRS}")
  message("GST_APP_LIBRARY_DIRS = ${GST_APP_LIBRARY_DIRS}")
  message("GST_APP_LIBRARIES = ${GST_APP_LIBRARIES}")
  #GST_APP_LIBRARIES = gstapp-1.0;gstbase-1.0;gstreamer-1.0;gobject-2.0;glib-2.0;intl
  #set(GST_APP_LIBRARIES "libgstapp-1.0;libgstbase-1.0;libgstreamer-1.0;libgobject-2.0;libglib-2.0;libintl")

  include_directories(${GST_APP_INCLUDE_DIRS})
  link_directories(${GST_APP_LIBRARY_DIRS})

  add_library(gstkvssink STATIC ${GST_PLUGIN_SOURCE_FILES})
  #add_library(gstkvssink ${GST_PLUGIN_SOURCE_FILES})

  target_link_libraries(gstkvssink 
    PUBLIC 
    ${GST_APP_LIBRARIES} 
    KinesisVideoProducer
  )

  target_include_directories(gstkvssink 
    PUBLIC 
    ${GST_APP_INCLUDE_DIRS}
  )
  install(
    DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/build/include
    DESTINATION .
  )

  #target_compile_options(gstkvssink
  #PUBLIC
  #  -Wno-unused-parameter
  #  -Wno-implicit-fallthrough
  #)

  #add_executable(kvs_gstreamer_sample samples/kvs_gstreamer_sample.cpp)
  #target_link_libraries(kvs_gstreamer_sample ${GST_APP_LIBRARIES} KinesisVideoProducer)

  #add_executable(kvs_gstreamer_multistream_sample samples/kvs_gstreamer_multistream_sample.cpp)
  #target_link_libraries(kvs_gstreamer_multistream_sample ${GST_APP_LIBRARIES} KinesisVideoProducer)

  #add_executable(kvs_gstreamer_audio_video_sample samples/kvs_gstreamer_audio_video_sample.cpp)
  #target_link_libraries(kvs_gstreamer_audio_video_sample ${GST_APP_LIBRARIES} KinesisVideoProducer)

  #add_executable(kvs_gstreamer_file_uploader_sample samples/kvs_gstreamer_file_uploader_sample.cpp)
  #target_link_libraries(kvs_gstreamer_file_uploader_sample ${GST_APP_LIBRARIES})
endif()

if(BUILD_TEST)
  set(ENV{KVS_GTEST_ROOT} ${KINESIS_VIDEO_OPEN_SOURCE_SRC})
  add_subdirectory(tst)
endif()

