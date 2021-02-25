#!/bin/bash

set -euo pipefail

TESTDIR='llvm/test/CodeGen/AMDGPU'

sed -i 's/; RUN: llc -mtriple=amdgcn-amd- -mcpu=gfx600/; RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx600/' "$TESTDIR"/memory-legalizer*.ll

llvm/utils/update_llc_test_checks.py -u "$TESTDIR"/memory-legalizer*.ll
llvm-lit "$TESTDIR"/memory-legalizer*.ll
