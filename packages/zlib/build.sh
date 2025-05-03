#!/bin/bash
set -e

# Metadata
MY_PKG_NAME="zlib"
MY_PKG_DESCRIPTION="Compression library"
MY_PKG_VERSION="1.3.1"  # Use the desired version
MY_PKG_LICENSE="Zlib"
MY_PKG_BUILD_IN_SRC=true

# Expected env vars:
# - NDK: path to Android NDK
# - API_LEVEL: API level (e.g. 24)
# - ARCH: target architecture (e.g., arm64, armeabi-v7a)
# - MY_PKG_PREFIX: destination install prefix

# Default to arm64 if not set
ARCH=${ARCH:-arm64}
API_LEVEL=${API_LEVEL:-21}  # Default API level to 21 if not set
MY_PKG_PREFIX=${MY_PKG_PREFIX:-/data/data/com.gebox.emu/files/usr/bionic}

# Set toolchain variables
TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
SYSROOT=$NDK/platforms/android-$API_LEVEL/arch-$ARCH

case "$ARCH" in
  arm64) ABI="aarch64-linux-android" ;;
  arm) ABI="arm-linux-androideabi" ;;
  x86) ABI="x86-linux-android" ;;
  x86_64) ABI="x86_64-linux-android" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Paths to the NDK tools
CC="$TOOLCHAIN/bin/$ABI$API_LEVEL-clang"
CXX="$TOOLCHAIN/bin/$ABI$API_LEVEL-clang++"
AR="$TOOLCHAIN/bin/$ABI-ar"
RANLIB="$TOOLCHAIN/bin/$ABI-ranlib"
LD="$TOOLCHAIN/bin/$ABI-ld"

# Download zlib source (or use a local copy)
ZLIB_SRC_DIR="zlib-$MY_PKG_VERSION"
ZLIB_TAR_URL="https://github.com/madler/zlib/releases/download/v${MY_PKG_VERSION}/zlib-${MY_PKG_VERSION}.tar.xz"

# Check if file exists before downloading
if [ ! -f "$ZLIB_SRC_DIR.tar.xz" ]; then
  echo "Downloading zlib source from $ZLIB_TAR_URL..."
  curl -L -O "$ZLIB_TAR_URL" || { echo "Failed to download $ZLIB_TAR_URL"; exit 1; }
fi

# Extract the source if not already extracted
if [ ! -d "$ZLIB_SRC_DIR" ]; then
  tar -xJf "$ZLIB_SRC_DIR.tar.xz" || { echo "Failed to extract $ZLIB_SRC_DIR.tar.xz"; exit 1; }
fi

# Create the build directory
mkdir -p $ZLIB_SRC_DIR/build

cd $ZLIB_SRC_DIR

# Configure zlib for cross-compilation
CC=$CC CXX=$CXX AR=$AR RANLIB=$RANLIB ./configure \
  --prefix=$MY_PKG_PREFIX \
  --static \
  --host=$ABI \
  --sysroot=$SYSROOT \
  --shared

# Build zlib
make -j$(nproc)

# Install the built package
make install

echo "zlib has been successfully built and installed at $MY_PKG_PREFIX"
