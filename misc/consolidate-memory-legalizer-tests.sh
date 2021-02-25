#!/bin/bash

set -euo pipefail

TMP="$(mktemp)"
trap '{ rm -f "$TMP"; }' EXIT

TESTDIR="llvm/test/CodeGen/AMDGPU"

strip_comments() {
  sed '/^ *[#;]/d' "$@"
}

strip_runlines() {
  sed '/^ *[#;] *RUN:/d' "$@"
}

surround_ir_test_names() {
  local PREPEND="$1" APPEND="$2" PREDICATE=''
  [ "$#" -gt 2 ] && PREDICATE="$3"
  sed "${PREDICATE}"'s/^\(.*define \+amdgpu_kernel \+void \+@\)\([^(]\+\)\((.*\)$/\1'"$PREPEND"'\2'"$APPEND"'\3/'
}

surround_mir_test_names() {
  local PREPEND="$1" APPEND="$2"
  sed 's/^\(name: *\)\(.*\)$/\1'"$PREPEND"'\2'"$APPEND"'/'
}

blank_line() {
  printf '\n'
}

# Note that memory-legalizer-{amdpal,mesa3d,atomic-fence}.ll differ only in RUN lines.
cat -s >"$TESTDIR/memory-legalizer.ll" \
  - \
  <(blank_line) \
  <(strip_comments "$TESTDIR/memory-legalizer-atomic-cmpxchg.ll" \
    | surround_ir_test_names 'flat_' '_cmpxchg') \
  <(blank_line) \
  <(strip_comments "$TESTDIR/memory-legalizer-atomic-rmw.ll" \
    | surround_ir_test_names 'flat_' '_atomicrmw') \
  <(blank_line) \
  <(strip_comments "$TESTDIR/memory-legalizer-atomic-fence.ll" \
    | surround_ir_test_names '' '_fence') \
  <(blank_line) \
  <(strip_comments "$TESTDIR/memory-legalizer-load.ll" \
    | sed '/declare i32 @llvm.amdgcn.workitem.id.x()/d' \
    | sed '/!0 =/d' \
    | surround_ir_test_names 'flat_' '_load' '/nontemporal_/!' \
    | sed 's/nontemporal_\([a-z]\+\)_\([0-9]\+\)/\1_nontemporal_load_\2/') \
  <(blank_line) \
  <(strip_comments "$TESTDIR/memory-legalizer-store.ll" \
    | sed '/declare i32 @llvm.amdgcn.workitem.id.x()/d' \
    | sed '/!0 =/d' \
    | surround_ir_test_names 'flat_' '_store' '/nontemporal_/!' \
    | sed 's/nontemporal_\([a-z]\+\)_\([0-9]\+\)/\1_nontemporal_store_\2/') \
  <(printf "\ndeclare i32 @llvm.amdgcn.workitem.id.x()\n\n!0 = !{i32 1}\n") \
  <(blank_line) \
  <<EOF
; RUN: llc -mtriple=amdgcn-amd-       -mcpu=gfx700 -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX7 %s
; RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx700 -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX7-HSA %s
; RUN: llc -mtriple=amdgcn-amd-amdpal -mcpu=gfx700 -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX7-PAL %s
; RUN: llc -mtriple=amdgcn-amd-amdpal -mcpu=gfx700 -amdgcn-skip-cache-invalidations -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX7-PAL-SKIP-CACHE-INV %s
; RUN: llc -mtriple=amdgcn-amd-mesa3d -mcpu=gfx700 -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX7-MESA %s
; RUN: llc -mtriple=amdgcn-amd-       -mcpu=gfx1010 -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX10-WGP %s
; RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx1010 -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX10-HSA-WGP %s
; RUN: llc -mtriple=amdgcn-amd-amdpal -mcpu=gfx1010 -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX10-PAL-WGP %s
; RUN: llc -mtriple=amdgcn-amd-amdpal -mcpu=gfx1010 -amdgcn-skip-cache-invalidations -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX10-PAL-SKIP-CACHE-INV-WGP %s
; RUN: llc -mtriple=amdgcn-amd-mesa3d -mcpu=gfx1010 -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX10-MESA-WGP %s
; RUN: llc -mtriple=amdgcn-amd-       -mcpu=gfx1010 -mattr=+cumode -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX10-CU %s
; RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx1010 -mattr=+cumode -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX10-HSA-CU %s
; RUN: llc -mtriple=amdgcn-amd-amdpal -mcpu=gfx1010 -amdgcn-skip-cache-invalidations -mattr=+cumode -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX10-PAL-SKIP-CACHE-INV-CU %s
; RUN: llc -mtriple=amdgcn-amd-amdpal -mcpu=gfx1010 -mattr=+cumode -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX10-PAL-CU %s
; RUN: llc -mtriple=amdgcn-amd-mesa3d -mcpu=gfx1010 -mattr=+cumode -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX10-MESA-CU %s
EOF
rm "$TESTDIR"/memory-legalizer-{amdpal,mesa3d,atomic-cmpxchg,atomic-rmw,atomic-fence,load,store}.ll

cat -s >"$TESTDIR/memory-legalizer-gfx6.ll" \
  - \
  <(blank_line) \
  <(strip_comments "$TESTDIR/memory-legalizer.ll" | awk '/flat_/ { in_flat=1 } /^$/ && in_flat { in_flat=0; next } !in_flat') \
  <<EOF
; RUN: llc -mtriple=amdgcn-amd-       -mcpu=gfx600 -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX6 %s
; RUN: llc -mtriple=amdgcn-amd-amdpal -mcpu=gfx600 -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX6-PAL %s
; RUN: llc -mtriple=amdgcn-amd-mesa3d -mcpu=gfx600 -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX6-MESA %s
EOF

cat -s >"$TESTDIR/memory-legalizer.mir" \
  - \
  <(blank_line) \
  <(strip_comments "$TESTDIR/memory-legalizer-local.mir" \
    | surround_mir_test_names 'local_' '') \
  <(strip_comments "$TESTDIR/memory-legalizer-region.mir" \
    | surround_mir_test_names 'region_' '') \
  <(strip_comments "$TESTDIR/memory-legalizer-multiple-mem-operands-atomics.mir") \
  <(strip_comments "$TESTDIR/memory-legalizer-multiple-mem-operands-nontemporal-1.mir" \
    | surround_mir_test_names '' '_nontemporal_1') \
  <(strip_comments "$TESTDIR/memory-legalizer-multiple-mem-operands-nontemporal-2.mir" \
    | surround_mir_test_names '' '_nontemporal_2') \
  <(strip_comments "$TESTDIR/memory-legalizer-atomic-insert-end.mir") \
  <(blank_line) \
  <<EOF
# RUN: llc -mtriple=amdgcn-amd-       -mcpu=gfx700 -run-pass=si-memory-legalizer -o - %s | FileCheck --check-prefixes=GFX7 %s
# RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx700 -run-pass=si-memory-legalizer -o - %s | FileCheck --check-prefixes=GFX7-HSA %s
# RUN: llc -mtriple=amdgcn-amd-amdpal -mcpu=gfx700 -run-pass=si-memory-legalizer -o - %s | FileCheck --check-prefixes=GFX7-PAL %s
# RUN: llc -mtriple=amdgcn-amd-mesa3d -mcpu=gfx700 -run-pass=si-memory-legalizer -o - %s | FileCheck --check-prefixes=GFX7-MESA %s
# RUN: llc -mtriple=amdgcn-amd-       -mcpu=gfx1010 -run-pass=si-memory-legalizer -o - %s | FileCheck --check-prefixes=GFX10-WGP %s
# RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx1010 -run-pass=si-memory-legalizer -o - %s | FileCheck --check-prefixes=GFX10-HSA-WGP %s
# RUN: llc -mtriple=amdgcn-amd-amdpal -mcpu=gfx1010 -run-pass=si-memory-legalizer -o - %s | FileCheck --check-prefixes=GFX10-PAL-WGP %s
# RUN: llc -mtriple=amdgcn-amd-mesa3d -mcpu=gfx1010 -run-pass=si-memory-legalizer -o - %s | FileCheck --check-prefixes=GFX10-MESA-WGP %s
# RUN: llc -mtriple=amdgcn-amd-       -mcpu=gfx1010 -mattr=+cumode -run-pass=si-memory-legalizer -o - %s | FileCheck --check-prefixes=GFX10-CU %s
# RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx1010 -mattr=+cumode -run-pass=si-memory-legalizer -o - %s | FileCheck --check-prefixes=GFX10-HSA-CU %s
# RUN: llc -mtriple=amdgcn-amd-amdpal -mcpu=gfx1010 -mattr=+cumode -run-pass=si-memory-legalizer -o - %s | FileCheck --check-prefixes=GFX10-PAL-CU %s
# RUN: llc -mtriple=amdgcn-amd-mesa3d -mcpu=gfx1010 -mattr=+cumode -run-pass=si-memory-legalizer -o - %s | FileCheck --check-prefixes=GFX10-MESA-CU %s
EOF
rm "$TESTDIR"/memory-legalizer-{local,region,multiple-mem-operands-{atomics,nontemporal-1,nontemporal-2},atomic-insert-end}.mir

cat -s >"$TMP" \
  - \
  <(blank_line) \
  <(strip_runlines "$TESTDIR/memory-legalizer-invalid-addrspace.mir") \
  <<EOF
# RUN: not llc -mtriple=amdgcn-amd-       -mcpu=gfx700 -run-pass=si-memory-legalizer -o - %s 2>&1 | FileCheck --check-prefixes=GCN %s
# RUN: not llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx700 -run-pass=si-memory-legalizer -o - %s 2>&1 | FileCheck --check-prefixes=GCN %s
# RUN: not llc -mtriple=amdgcn-amd-amdpal -mcpu=gfx700 -run-pass=si-memory-legalizer -o - %s 2>&1 | FileCheck --check-prefixes=GCN %s
# RUN: not llc -mtriple=amdgcn-amd-mesa3d -mcpu=gfx700 -run-pass=si-memory-legalizer -o - %s 2>&1 | FileCheck --check-prefixes=GCN %s
# RUN: not llc -mtriple=amdgcn-amd-       -mcpu=gfx1010 -run-pass=si-memory-legalizer -o - %s 2>&1 | FileCheck --check-prefixes=GCN %s
# RUN: not llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx1010 -run-pass=si-memory-legalizer -o - %s 2>&1 | FileCheck --check-prefixes=GCN %s
# RUN: not llc -mtriple=amdgcn-amd-amdpal -mcpu=gfx1010 -run-pass=si-memory-legalizer -o - %s 2>&1 | FileCheck --check-prefixes=GCN %s
# RUN: not llc -mtriple=amdgcn-amd-mesa3d -mcpu=gfx1010 -run-pass=si-memory-legalizer -o - %s 2>&1 | FileCheck --check-prefixes=GCN %s
# RUN: not llc -mtriple=amdgcn-amd-       -mcpu=gfx1010 -mattr=+cumode -run-pass=si-memory-legalizer -o - %s 2>&1 | FileCheck --check-prefixes=GCN %s
# RUN: not llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx1010 -mattr=+cumode -run-pass=si-memory-legalizer -o - %s 2>&1 | FileCheck --check-prefixes=GCN %s
# RUN: not llc -mtriple=amdgcn-amd-amdpal -mcpu=gfx1010 -mattr=+cumode -run-pass=si-memory-legalizer -o - %s 2>&1 | FileCheck --check-prefixes=GCN %s
# RUN: not llc -mtriple=amdgcn-amd-mesa3d -mcpu=gfx1010 -mattr=+cumode -run-pass=si-memory-legalizer -o - %s 2>&1 | FileCheck --check-prefixes=GCN %s
EOF
cp "$TMP" "$TESTDIR/memory-legalizer-invalid-addrspace.mir"

cat -s >"$TMP" \
  - \
  <(blank_line) \
  <(strip_runlines "$TESTDIR/memory-legalizer-invalid-syncscope.ll") \
  <<EOF
; RUN: not llc -mtriple=amdgcn-amd-       -mcpu=gfx700 -verify-machineinstrs < %s 2>&1 | FileCheck %s
; RUN: not llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx700 -verify-machineinstrs < %s 2>&1 | FileCheck %s
; RUN: not llc -mtriple=amdgcn-amd-amdpal -mcpu=gfx700 -verify-machineinstrs < %s 2>&1 | FileCheck %s
; RUN: not llc -mtriple=amdgcn-amd-mesa3d -mcpu=gfx700 -verify-machineinstrs < %s 2>&1 | FileCheck %s
; RUN: not llc -mtriple=amdgcn-amd-       -mcpu=gfx1010 -verify-machineinstrs < %s 2>&1 | FileCheck %s
; RUN: not llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx1010 -verify-machineinstrs < %s 2>&1 | FileCheck %s
; RUN: not llc -mtriple=amdgcn-amd-amdpal -mcpu=gfx1010 -verify-machineinstrs < %s 2>&1 | FileCheck %s
; RUN: not llc -mtriple=amdgcn-amd-mesa3d -mcpu=gfx1010 -verify-machineinstrs < %s 2>&1 | FileCheck %s
; RUN: not llc -mtriple=amdgcn-amd-       -mcpu=gfx1010 -mattr=+cumode -verify-machineinstrs < %s 2>&1 | FileCheck %s
; RUN: not llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx1010 -mattr=+cumode -verify-machineinstrs < %s 2>&1 | FileCheck %s
; RUN: not llc -mtriple=amdgcn-amd-amdpal -mcpu=gfx1010 -mattr=+cumode -verify-machineinstrs < %s 2>&1 | FileCheck %s
; RUN: not llc -mtriple=amdgcn-amd-mesa3d -mcpu=gfx1010 -mattr=+cumode -verify-machineinstrs < %s 2>&1 | FileCheck %s
EOF
cp "$TMP" "$TESTDIR/memory-legalizer-invalid-syncscope.ll"

llvm/utils/update_llc_test_checks.py "$TESTDIR"/memory-legalizer{,-gfx6}.ll
llvm/utils/update_mir_test_checks.py "$TESTDIR/memory-legalizer.mir"
llvm-lit "$TESTDIR"/memory-legalizer*.{ll,mir}
