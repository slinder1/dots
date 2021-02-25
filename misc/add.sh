#!/bin/bash

set -euo pipefail

TMP="$(mktemp)"
trap '{ rm -f "$TMP"; }' EXIT

TESTDIR='llvm/test/CodeGen/AMDGPU'

RUNLINES="$(cat <<EOF
; RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx90a -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX90A-NOTTGSPLIT %s
; RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx90a -mattr=+tgsplit -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX90A-TGSPLIT %s
; RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx90b -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX90B-NOTTGSPLIT %s
; RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx90b -mattr=+tgsplit -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX90B-TGSPLIT %s
EOF
)"
AWK_PROGRAM="$(cat <<EOF
insert {
  if (!inserted) {
    print runlines;
    inserted=1;
  }
  insert=0;
}
/RUN.*-mcpu=gfx700/ { insert=1 }
{ print }
EOF
)"

rm -f "$TESTDIR"/memory-legalizer-gfx90{a,b}.ll

for f in "$TESTDIR"/memory-legalizer*.ll; do
  if [[ $f == *invalid-syncscope.ll || $f == *store-infinite-loop.ll ]]; then
    continue
  fi
  awk -v runlines="$RUNLINES" -- "$AWK_PROGRAM" "$f" >"$TMP"
  cp "$TMP" "$f"
done

llvm/utils/update_llc_test_checks.py -u "$TESTDIR"/memory-legalizer*.ll
llvm-lit "$TESTDIR"/memory-legalizer*.ll
