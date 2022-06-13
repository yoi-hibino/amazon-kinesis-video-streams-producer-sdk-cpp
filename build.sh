PATH_PREV=/root/tools/androidsdk/cmdline-tools/latest/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:
#/root/tools/androidsdk/cmdline-tools/latest/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/tools/androidsdk/ndk/23.0.7599858/toolchains/llvm/prebuilt/linux-x86_64/bin:/root/tools/androidsdk/ndk/23.0.7599858/toolchains/llvm/prebuilt/linux-x86_64/bin:/root/tools/androidsdk/ndk/23.0.7599858/toolchains/llvm/prebuilt/linux-x86_64/bin


#/root/tools/androidsdk/cmake/3.18.1/bin/cmake

SDK_ROOT=/root/tools/androidsdk
NDK_DIR=${SDK_ROOT}/ndk/22.1.7171670
#24.0.8215888
#23.0.7599858
NDK_BIN_DIR=${NDK_DIR}/toolchains/llvm/prebuilt/linux-x86_64/bin
CMAKE_BIN_DIR=${SDK_ROOT}/cmake/3.18.1/bin

export PATH=$PATH_PREV:$NDK_BIN_DIR

export ANDROID_NDK_ROOT=$NDK_DIR
export ANDROID_NDK_HOME=$NDK_DIR
export ANDROID_NDK=$NDK_DIR
export API_LEVEL=24
export NDK=$NDK_DIR
export TOOLCHAIN=${NDK_DIR}/toolchains/llvm/prebuilt/linux-x86_64

#GSTREAMER_DIR=/root/develop/test3/gstreamer-1.0
GSTREAMER_DIR=/home/jan/devel/gstreamer/cerbero/build/sources/android_universal
#export PATH=$PATH:$NDK_BIN_DIR:$GSTREAMER_DIR/include:$GSTREAMER_DIR/lib

#android-arm, android-arm64, android-x86 and android-x86_64
ARCHS=("android-arm" "android-arm64" "android-x86" "android-x86_64")
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")
HOSTS=("arm-linux-androideabi" "aarch64-linux-android" "i686-linux-android" "x86_64-linux-android")
ABIS2=("armv7" "arm64" "x86" "x86_64")

#ARCHS=("android-arm" "android-x86" "android-x86_64")
#ABIS=("armeabi-v7a" "x86" "x86_64")
#HOSTS=("arm-linux-androideabi" "i686-linux-android" "x86_64-linux-android")
#ABIS2=("armv7" "x86" "x86_64")

#ARCHS=("android-arm64" "android-x86" "android-x86_64")
#ABIS=("arm64-v8a" "x86" "x86_64")
#HOSTS=("aarch64-linux-android" "i686-linux-android" "x86_64-linux-android")
#ABIS2=("arm64" "x86" "x86_64")

#ARCHS=("android-arm")
#ABIS=("armeabi-v7a")
#HOSTS=("arm-linux-androideabi")
#ABIS2=("armv7")

PRJ_ROOT=${PWD}
BUILD_DIR=${PRJ_ROOT}/build
OUTPUT_DIR=${PRJ_ROOT}/output

rm -rf ${BUILD_DIR}
rm -rf ${OUTPUT_DIR}
#rm -rf ${PRJ_ROOT}/open-source

mkdir -p ${BUILD_DIR}
mkdir -p ${OUTPUT_DIR}
mkdir -p ${PRJ_ROOT}/open-source

echo ${BUILD_DIR}
which cmake
${CMAKE_BIN_DIR}/cmake --version

export OPEN_SOURCE_DIR=${PRJ_ROOT}/open-source/local
echo "OPEN_SOURCE_DIR=${OPEN_SOURCE_DIR}"
echo ${NDK_BIN_DIR}

#cd ${BUILD_DIR}

for ((i=0; i < ${#ABIS[@]}; i++))
do
  rm -rf ${BUILD_DIR}
  rm -rf ${PRJ_ROOT}/open-source
  rm -rf ${PRJ_ROOT}/dependency
  mkdir -p ${BUILD_DIR}

  cd ${BUILD_DIR}

  export ABI=${ABIS[i]}
  export ANDROID_ARCH=${ARCHS[i]}

  ABI2=${ABIS2[i]}
  TOOLCHAIN_NAME=${HOSTS[i]}

  OUTPUT_PATH=${OUTPUT_DIR}/${ABI}
  OUTPUT_LIB_PATH=${OUTPUT_PATH}/lib
  mkdir -p ${OUTPUT_LIB_PATH}

  echo ${ABI}
  echo ${TOOLCHAIN_NAME}
  echo ${API_LEVEL}
  echo ${OUTPUT_PLUGIN_PATH}

  export PKG_CONFIG_PATH=${GSTREAMER_DIR}/${ABI2}/lib/pkgconfig

  export CC=${NDK_BIN_DIR}/clang
  export CXX=${NDK_BIN_DIR}/clang++
  export AS=${NDK_BIN_DIR}/llvm-as
 # export CC=${NDK_BIN}/${TOOLCHAIN_NAME}${API_LEVEL}-clang
 # export CXX=${NDK_BIN}/${TOOLCHAIN_NAME}${API_LEVEL}-clang++
 # export AS=${NDK_BIN}/${TOOLCHAIN_NAME}${API_LEVEL}-as
  export LD=${NDK_BIN_DIR}/ld
  export AR=${NDK_BIN_DIR}/llvm-ar
  export RANLIB=${NDK_BIN_DIR}/llvm-ranlib
  export STRIP=${NDK_BIN_DIR}/llvm-strip
  export NM=${NDK_BIN_DIR}/llvm-nm
  
  cmake \
    -DCMAKE_FIND_ROOT_PATH="${OPEN_SOURCE_DIR};${GSTREAMER_DIR}/${ABI2}" \
    -DCMAKE_TOOLCHAIN_FILE=${NDK_DIR}/build/cmake/android.toolchain.cmake \
    -DANDROID_NDK_ROOT=${ANDROID_NDK_ROOT} \
    -DANDROID_TOOLCHAIN=clang \
    -DANDROID_ABI=${ABI} \
    -DGST_ABI=${ABI2} \
    -DANDROID_NDK=${NDK_DIR} \
    -DANDROID_PLATFORM=android-${API_LEVEL} \
    -DANDROID_API_LEVEL=${API_LEVEL} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DCMAKE_ANDROID_ARCH_ABI=${ABI} \
    -DCMAKE_ANDROID_NDK=${NDK_DIR} \
    -DCMAKE_SYSTEM_NAME=Android \
    -DCMAKE_SYSTEM_VERSION=${API_LEVEL} \
    -DOPENSSL_EXTRA=${OPENSSL_EXTRA} \
    -DANDROID_ARCH=${ANDROID_ARCH} \
    -DBUILD_DEPENDENCIES=TRUE \
    -DBUILD_GSTREAMER_PLUGIN=TRUE \
    ..

  make 
  #make DESTDIR=${OUTPUT_PATH} install

  #if [ -f ${BUILD_DIR}/libKinesisVideoProducer.so -a -f ${BUILD_DIR}/libgstkvssink.a ]; then
  #  cp ${BUILD_DIR}/libKinesisVideoProducer.so  ${BUILD_DIR}/libgstkvssink.a ${OUTPUT_PLUGIN_PATH}
  #fi
  cp ${BUILD_DIR}/libKinesisVideoProducer.so ${BUILD_DIR}/libgstkvssink.a ${OUTPUT_LIB_PATH}
  cp -RT ${PRJ_ROOT}/open-source/local/lib ${OUTPUT_LIB_PATH}
  cp -R ${PRJ_ROOT}/open-source/local/include ${OUTPUT_LIB_PATH} ${OUTPUT_PATH}

  #build/dependency/libkvscproducer/kvscproducer-src/dependency/libkvspic/kvspic-src/libkvspicUtils.a
  #build/dependency/libkvscproducer/kvscproducer-src/dependency/libkvspic/kvspic-src/libkvspic.a
  KVSPIC_DIR=${BUILD_DIR}/dependency/libkvscproducer/kvscproducer-src/dependency/libkvspic/kvspic-src
  cp ${KVSPIC_DIR}/libkvspic.a ${KVSPIC_DIR}/libkvspicUtils.a ${OUTPUT_LIB_PATH}

  cd $PRJ_ROOT

done

#cd $PRJ_ROOT
export PATH=$PATH_PREV

