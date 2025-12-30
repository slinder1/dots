#!/bin/bash

set -e

REF=42129deaa67b6c4b8fc82feb74b7e9fe25c99073

if [[ ! -d llvm-project ]]; then
  git clone --depth=1 --branch="$REF" https://github.com/llvm/llvm-project
fi

export CC=gcc
export CXX=g++

if [ ! -d release-gcc ]; then
  mkdir -p release-gcc
  pushd release-gcc
  cmake -GNinja -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$HOME" \
    -DCMAKE_C_FLAGS=-w -DCMAKE_CXX_FLAGS=-w \
    -DLLVM_INCLUDE_TESTS=Off -DLLVM_TARGETS_TO_BUILD=X86 \
    -DLLVM_ENABLE_PROJECTS="llvm;clang;lld;clang-tools-extra" \
    -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind;compiler-rt" \
    "-DCMAKE_C_COMPILER=$CC" \
    "-DCMAKE_CXX_COMPILER=$CXX" \
    -DLLVM_CCACHE_BUILD=On -DLLVM_CCACHE_MAXSIZE=256G \
    ../llvm-project/llvm
  ninja
  ninja install
  popd
fi

CC="$HOME/bin/clang"
CXX="$HOME/bin/clang++"

if [ ! -d release-bolt ]; then
  mkdir -p release-bolt
  pushd release-bolt
  cmake -GNinja -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$HOME" \
    "-DCMAKE_C_COMPILER=$CC" \
    "-DCMAKE_CXX_COMPILER=$CXX" \
    -DLLVM_CCACHE_BUILD=On -DLLVM_CCACHE_MAXSIZE=256G \
    -C ../llvm-project/clang/cmake/caches/BOLT-PGO.cmake \
    -DBOOTSTRAP_LLVM_ENABLE_LLD=ON \
    -DBOOTSTRAP_BOOTSTRAP_LLVM_ENABLE_LLD=ON \
    -DPGO_INSTRUMENT_LTO=Thin \
    ../llvm-project/llvm
  ninja stage2-clang-bolt
  #ninja stage2-install-distribution
  popd
fi

#mkdir -p libcxx-asan
#pushd libcxx-asan
#cmake -GNinja -DCMAKE_BUILD_TYPE=Release \
#  -DCMAKE_INSTALL_PREFIX="$HOME" \
#  -DCMAKE_C_FLAGS=-w -DCMAKE_CXX_FLAGS=-w \
#  -DLLVM_INCLUDE_TESTS=Off -DLLVM_TARGETS_TO_BUILD=X86 \
#  -DLLVM_ENABLE_PROJECTS="" \
#  -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi" \
#  "-DCMAKE_C_COMPILER=$CC" \
#  "-DCMAKE_CXX_COMPILER=$CXX" \
#  -DLLVM_USE_SANITIZER='Address' \
#  -DLLVM_USE_LINKER='lld' \
#  -DLLVM_CCACHE_BUILD=On -DLLVM_CCACHE_MAXSIZE=256G \
#  ../llvm-project/llvm
#ninja cxx cxxabi
#ninja install
#popd

mkdir -p "$HOME/etc"
sh -c "cat >"$HOME"/etc/cc.env" <<EOF
export CC='$CC'
export CXX='$CXX'
export ASAN_OPTIONS=check_initialization_order=true:detect_stack_use_after_return=1:detect_leaks=1
EOF
