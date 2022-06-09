#/root/tools/androidsdk/cmake/3.18.1/bin/cmake
SDK_ROOT=/root/tools/androidsdk
NDK_DIR=${SDK_ROOT}/ndk/23.0.7599858
NDK_BIN_DIR=${NDK_DIR}/toolchains/llvm/prebuilt/linux-x86_64/bin
CMAKE_BIN_DIR=${SDK_ROOT}/cmake/3.18.1/bin

export API_LEVEL=23

ARCHS=("android-arm" "android-arm64" "android-x86" "android-x86_64")
#ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")
ABIS=("armeabi-v7a")
HOSTS=("arm-linux-androideabi" "aarch64-linux-android" "i686-linux-android" "x86_64-linux-android")
ABIS2=("armv7" "arm64" "x86" "x86_64")

PRJ_ROOT=${PWD}
BUILD_DIR=${PRJ_ROOT}/build

rm -rf ${BUILD_DIR}
rm -rf ${PRJ_ROOT}/open_source

mkdir -p ${BUILD_DIR}
mkdir -p ${PRJ_ROOT}/open_source

echo ${BUILD_DIR}
which cmake
${CMAKE_BIN_DIR}/cmake --version

OPEN_SOURCE_DIR=${PRJ_ROOT}/open-source/local
echo ${OPEN_SOURCE_DIR}
echo ${NDK_BIN_DIR}

cd ${BUILD_DIR}

for ((i=0; i < ${#ABIS[@]}; i++))
do
export ABI=${ABIS[i]}
  export ANDROID_ARCH=${ARCHS[i]}
  ABI2=${ABIS2[i]}
  TOOLCHAIN_NAME=${HOSTS[i]}

  echo ${ABI}
  echo ${TOOLCHAIN_NAME}
  echo ${API_LEVEL}

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
    -DCMAKE_FIND_ROOT_PATH=${OPEN_SOURCE_DIR} \
    -DCMAKE_TOOLCHAIN_FILE=${NDK_DIR}/build/cmake/android.toolchain.cmake \
    -DANDROID_TOOLCHAIN=clang \
    -DANDROID_ABI=${ABI} \
    -DANDROID_NDK=${NDK_DIR} \
    -DANDROID_PLATFORM=android-${API_LEVEL} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DCMAKE_ANDROID_ARCH_ABI=${ABI} \
    -DCMAKE_ANDROID_NDK=${NDK_DIR} \
    -DCMAKE_SYSTEM_NAME=Android \
    -DCMAKE_SYSTEM_VERSION=${API_LEVEL} \
    -DOPENSSL_EXTRA=${OPENSSL_EXTRA} \
    -DANDROID_ARCH=${ANDROID_ARCH} \
    -DBUILD_DEPENDENCIES=TRUE \
    ..

  make 

done

cd $PRJ_ROOT