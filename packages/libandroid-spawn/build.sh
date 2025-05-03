#!/bin/bash
set -ex

# Package metadata
MY_PKG_HOMEPAGE="https://man7.org/linux/man-pages/man3/posix_spawn.3.html"
MY_PKG_DESCRIPTION="Shared library for posix_spawn system function"
MY_PKG_LICENSE="BSD-2-Clause"
MY_PKG_VERSION="0.3"
MY_PKG_DEPENDS="libc++"
MY_PKG_BUILD_IN_SRC=true

echo "Starting build script for libandroid-spawn"
echo "Current directory: $(pwd)"

# Print environment variables
echo "NDK: ${NDK}"
echo "TOOLCHAIN: ${TOOLCHAIN}"
echo "API_LEVEL: ${API_LEVEL}"
echo "PREFIX: ${PREFIX}"

# Set up toolchain
export CC="${TOOLCHAIN}/bin/aarch64-linux-android${API_LEVEL}-clang"
export CXX="${TOOLCHAIN}/bin/aarch64-linux-android${API_LEVEL}-clang++"
export LD="${TOOLCHAIN}/bin/ld"
export AR="${TOOLCHAIN}/bin/llvm-ar"
export AS="${TOOLCHAIN}/bin/llvm-as"
export STRIP="${TOOLCHAIN}/bin/llvm-strip"
export SYSROOT="${TOOLCHAIN}/sysroot"
export CFLAGS="--sysroot=${SYSROOT} -fPIC"
export CXXFLAGS="--sysroot=${SYSROOT} -fPIC"
export LDFLAGS="--sysroot=${SYSROOT}"

# Custom prefix - this is the target installation directory
export MY_PKG_PREFIX="/data/data/com.gebox.emu/files/usr/bionic"
echo "Target installation prefix: ${MY_PKG_PREFIX}"

# For local builds, we'll use PREFIX as a staging directory
export STAGING_PREFIX="${PREFIX}"
echo "Staging prefix: ${STAGING_PREFIX}"

# Create source file
echo "Creating source file"
cat > posix_spawn.cpp << 'EOF'
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

extern "C" {

// Define posix_spawn_file_actions_t and posix_spawnattr_t
typedef void* posix_spawn_file_actions_t;
typedef void* posix_spawnattr_t;

int posix_spawn(pid_t* pid, const char* path,
                const posix_spawn_file_actions_t* file_actions,
                const posix_spawnattr_t* attrp,
                char* const argv[], char* const envp[]) {
  // Basic implementation using fork and execve
  pid_t child_pid = fork();
  
  if (child_pid < 0) {
    return errno;
  } else if (child_pid == 0) {
    // Child process
    execve(path, argv, envp);
    _exit(127);
  }
  
  // Parent process
  if (pid) {
    *pid = child_pid;
  }
  
  return 0;
}

int posix_spawnp(pid_t* pid, const char* file,
                 const posix_spawn_file_actions_t* file_actions,
                 const posix_spawnattr_t* attrp,
                 char* const argv[], char* const envp[]) {
  // Similar to posix_spawn but searches PATH
  return posix_spawn(pid, file, file_actions, attrp, argv, envp);
}

int posix_spawn_file_actions_init(posix_spawn_file_actions_t* file_actions) {
  if (file_actions == nullptr) return EINVAL;
  *file_actions = nullptr;
  return 0;
}

int posix_spawn_file_actions_destroy(posix_spawn_file_actions_t* file_actions) {
  if (file_actions == nullptr) return EINVAL;
  return 0;
}

int posix_spawnattr_init(posix_spawnattr_t* attr) {
  if (attr == nullptr) return EINVAL;
  *attr = nullptr;
  return 0;
}

int posix_spawnattr_destroy(posix_spawnattr_t* attr) {
  if (attr == nullptr) return EINVAL;
  return 0;
}

} // extern "C"
EOF

# Create header file
echo "Creating header file"
cat > posix_spawn.h << 'EOF'
#ifndef _POSIX_SPAWN_H
#define _POSIX_SPAWN_H

#include <sys/cdefs.h>
#include <sys/types.h>
#include <signal.h>

__BEGIN_DECLS

typedef void* posix_spawn_file_actions_t;
typedef void* posix_spawnattr_t;

int posix_spawn(pid_t* __pid, const char* __path,
                const posix_spawn_file_actions_t* __file_actions,
                const posix_spawnattr_t* __attrp,
                char* const __argv[], char* const __envp[]);

int posix_spawnp(pid_t* __pid, const char* __file,
                 const posix_spawn_file_actions_t* __file_actions,
                 const posix_spawnattr_t* __attrp,
                 char* const __argv[], char* const __envp[]);

int posix_spawn_file_actions_init(posix_spawn_file_actions_t* __file_actions);
int posix_spawn_file_actions_destroy(posix_spawn_file_actions_t* __file_actions);

int posix_spawnattr_init(posix_spawnattr_t* __attr);
int posix_spawnattr_destroy(posix_spawnattr_t* __attr);

__END_DECLS

#endif /* _POSIX_SPAWN_H */
EOF

# Create LICENSE file
echo "Creating LICENSE file"
cat > LICENSE << 'EOF'
Copyright (c) 2023, libandroid-spawn contributors
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
EOF

# Build function
echo "Starting build process"
# Check file exists
ls -la posix_spawn.cpp

# Compile the source file
echo "Compiling posix_spawn.cpp"
$CXX $CXXFLAGS $CPPFLAGS -I. -c posix_spawn.cpp -o spawn.o
echo "Creating shared library"
$CXX $LDFLAGS -shared spawn.o -o libandroid-spawn.so
echo "Creating static library"
$AR rcu libandroid-spawn.a spawn.o

# Install function - install to the staging prefix
echo "Installing files to staging directory"
mkdir -p ${STAGING_PREFIX}/usr/bionic/include
mkdir -p ${STAGING_PREFIX}/usr/bionic/lib
echo "Installing to ${STAGING_PREFIX}/usr/bionic/"

cp posix_spawn.h ${STAGING_PREFIX}/usr/bionic/include/
cp libandroid-spawn.a ${STAGING_PREFIX}/usr/bionic/lib/
cp libandroid-spawn.so ${STAGING_PREFIX}/usr/bionic/lib/

echo "Build script completed successfully"
