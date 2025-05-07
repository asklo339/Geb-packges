#!/bin/bash
set -e

# Metadata
MY_PKG_NAME="zlib"
MY_PKG_DESCRIPTION="Compression library"
MY_PKG_VERSION="1.3.1"
MY_PKG_LICENSE="Zlib"
MY_PKG_BUILD_IN_SRC=true

# Expected env vars:
# - NDK: path to Android NDK
# - API_LEVEL: API level (e.g. 24)
# - ARCH: target architecture (e.g., arm64-v8a, armeabi-v7a, x86, x86_64)
# - MY_PKG_PREFIX: destination install prefix

# Validate NDK
if [ -z "$NDK" ]; then
    echo "Error: NDK environment variable not set"
    exit 1
fi

# Default values
ARCH=${ARCH:-arm64-v8a}
API_LEVEL=${API_LEVEL:-21}
MY_PKG_PREFIX=${MY_PKG_PREFIX:-/data/data/com.gebox.emu/files/usr/bionic}

# Set toolchain variables
TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64

# Map Android ABI to toolchain arch
case "$ARCH" in
    arm64-v8a)
        TARGET=aarch64-linux-android
        ;;
    armeabi-v7a)
        TARGET=armv7a-linux-androideabi
        ;;
    x86)
        TARGET=i686-linux-android
        ;;
    x86_64)
        TARGET=x86_64-linux-android
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Set compiler and tools
export CC="$TOOLCHAIN/bin/$TARGET$API_LEVEL-clang"
export CXX="$TOOLCHAIN/bin/$TARGET$API_LEVEL-clang++"
export AR="$TOOLCHAIN/bin/llvm-ar"
export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
export STRIP="$TOOLCHAIN/bin/llvm-strip"

# Download zlib source
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

cd $ZLIB_SRC_DIR

# Configure zlib for cross-compilation
# Note: zlib's configure doesn't support --host option, we use environment variables instead
echo "Configuring zlib for Android $ARCH API level $API_LEVEL..."
./configure \
    --prefix=$MY_PKG_PREFIX \
    --shared

# Build zlib
echo "Building zlib..."
make -j$(nproc)

# Install the built package
echo "Installing zlib to $MY_PKG_PREFIX..."
make install

echo "zlib $MY_PKG_VERSION has been successfully built and installed at $MY_PKG_PREFIX"
