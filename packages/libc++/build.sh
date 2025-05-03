#!/bin/bash
set -ex

# Metadata
MY_PKG_NAME="libc++"
MY_PKG_DESCRIPTION="NDK shared and static libc++"
MY_PKG_VERSION="NDK"
MY_PKG_LICENSE="LLVM"
MY_PKG_BUILD_IN_SRC=true

# Expected env vars:
# - NDK: path to Android NDK
# - API_LEVEL: API level (e.g. 24 or 34)
# - ARCH: target arch (e.g. arm64, arm, x86, x86_64)
# - MY_PKG_PREFIX: destination install prefix

# Default values
ARCH=${ARCH:-arm64}
API_LEVEL=${API_LEVEL:-24}
MY_PKG_PREFIX=${MY_PKG_PREFIX:-/data/data/com.gebox.emu/files/usr/bionic}

# Determine target triple based on ARCH.
case "$ARCH" in
  arm64) TRIPLE="aarch64-linux-android" ;;
  arm) TRIPLE="arm-linux-androideabi" ;;
  x86) TRIPLE="i686-linux-android" ;;
  x86_64) TRIPLE="x86_64-linux-android" ;;
  *) echo "Unsupported arch: $ARCH"; exit 1 ;;
esac

# First, try to find libc++_shared.so in the API-level folder.
LIBCXX_SHARED_SRC="$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/$TRIPLE/$API_LEVEL/libc++_shared.so"
LIBCXX_STATIC_SRC="$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/$TRIPLE/$API_LEVEL/libc++_static.a"

if [ ! -f "$LIBCXX_SHARED_SRC" ]; then
  echo "libc++_shared.so not found at $LIBCXX_SHARED_SRC, trying without API level..."
  # Fallback: try without API level folder
  LIBCXX_SHARED_SRC="$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/$TRIPLE/libc++_shared.so"
  LIBCXX_STATIC_SRC="$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/$TRIPLE/libc++_static.a"
fi

if [ ! -f "$LIBCXX_SHARED_SRC" ]; then
  echo "libc++_shared.so not found at expected locations:"
  echo "  - $LIBCXX_SHARED_SRC"
  exit 1
fi

if [ ! -f "$LIBCXX_STATIC_SRC" ]; then
  echo "libc++_static.a not found at expected locations:"
  echo "  - $LIBCXX_STATIC_SRC"
  exit 1
fi

# Install the libraries to MY_PKG_PREFIX/lib.
cp "$LIBCXX_SHARED_SRC" "$MY_PKG_PREFIX/usr/bionic/lib/libc++_shared.so"
cp "$LIBCXX_STATIC_SRC" "$MY_PKG_PREFIX/usr/bionic/lib/libc++_static.a"

echo "Installed libc++_shared.so and libc++_static.a to $MY_PKG_PREFIX/lib"
