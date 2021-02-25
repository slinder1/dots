#!/bin/bash

set -euo pipefail

PREFIX="llvm/test/CodeGen/AMDGPU/memory-legalizer"

test_names() {
  sed -n 's/.*define.*\(@.*\)(.*/\1/p'
}

new_files() {
  git ls-files --others --exclude-standard
}

declare -A tests
tests+=(["fence"]="/@.*_fence\\(/")
for space in flat global local private; do
  tests+=(["${space}-nontemporal"]="/@${space}_nontemporal_/")
done
for space_scope in {flat,global,local}-{system,agent,workgroup,wavefront,singlethread}; do
  tests+=(["$space_scope"]="/@${space_scope//-/_}/")
done

for key in ${!tests[@]}; do
  if [[ $key != flat-* ]]; then
    cat >>"$PREFIX-$key.ll" <<EOF
; RUN: llc -mtriple=amdgcn-amd- -mcpu=gfx600 -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX6 %s
EOF
  fi
  cat >>"$PREFIX-$key.ll" <<EOF
; RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx700 -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX7 %s
; RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx1010 -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX10-WGP %s
; RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx1010 -mattr=+cumode -verify-machineinstrs < %s | FileCheck --check-prefixes=GFX10-CU %s
; RUN: llc -mtriple=amdgcn-amd-amdpal -mcpu=gfx700 -amdgcn-skip-cache-invalidations -verify-machineinstrs < %s | FileCheck --check-prefixes=SKIP-CACHE-INV %s
EOF
  sed '/^[;#]/d' "$PREFIX.ll" | awk -- "${tests[${key}]} { p=1 } /^$/ { p=0; print } p" | cat -s >>"$PREFIX-$key.ll"
  grep -q '!0' "$PREFIX-$key.ll" && printf "!0 = !{i32 1}\n" >>"$PREFIX-$key.ll"
  grep -q '@llvm.amdgcn.workitem.id.x' "$PREFIX-$key.ll" && printf "declare i32 @llvm.amdgcn.workitem.id.x()\n" >>"$PREFIX-$key.ll"
done

printf '\n[+] Missing from new tests:\n'
! grep --fixed-strings --invert-match --file=<(cat $(new_files) | test_names) <(cat "$PREFIX.ll" | test_names)

printf '\n[+] Duplicated in new tests:\n'
! diff <(cat $(new_files) | test_names | sort) <(cat $(new_files) | test_names | sort -u)

printf '\n[+] Empty new tests:\n'
! wc -c $(new_files) | awk '$1 <= 1 { print $2 }'

llvm/utils/update_llc_test_checks.py $(new_files)
