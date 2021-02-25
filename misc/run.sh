#!/bin/bash

ninja -C release llc
release/bin/llc < llvm/test/CodeGen/AMDGPU/stack-pointer-offset-relative-frameindex.ll -march=amdgcn -mcpu=gfx1010 -verify-machineinstrs -print-after-all 2>&1 | grep -q '\$sp_reg'
