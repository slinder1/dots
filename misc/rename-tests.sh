#!/bin/bash

set -euo pipefail

TMP="$(mktemp)"
trap '{ rm -f "$TMP"; }' EXIT

TESTDIR="llvm/test/CodeGen/AMDGPU"

strip_comments() {
  sed '/RUN:/!{/^ *[#;]/d}' "$@"
}

surround_ir_test_names() {
  local TEST="$TESTDIR/$1" PREPEND="$2" APPEND="$3" PREDICATE=''
  [ "$#" -gt 3 ] && PREDICATE="$4"
  strip_comments "$TEST" \
      | sed "${PREDICATE}"'s/^\(.*define \+amdgpu_kernel \+void \+@\)\([^(]\+\)\((.*\)$/\1'"$PREPEND"'\2'"$APPEND"'\3/' \
    >"$TMP"
  cp "$TMP" "$TEST"
}

surround_mir_test_names() {
  local TEST="$TESTDIR/$1" PREPEND="$2" APPEND="$3"
  strip_comments "$TEST" \
      | sed 's/^\(name: *\)\(.*\)$/\1'"$PREPEND"'\2'"$APPEND"'/' \
    >"$TMP"
  cp "$TMP" "$TEST"
}

surround_ir_test_names memory-legalizer-atomic-cmpxchg.ll flat_ _cmpxchg
surround_ir_test_names memory-legalizer-atomic-rmw.ll flat_ _atomicrmw
surround_ir_test_names memory-legalizer-atomic-fence.ll '' _fence
surround_ir_test_names memory-legalizer-load.ll flat_ _load /nontemporal_/!
surround_ir_test_names memory-legalizer-load.ll '' _load /nontemporal_/
surround_ir_test_names memory-legalizer-store.ll flat_ _store /nontemporal_/!
surround_ir_test_names memory-legalizer-store.ll '' _store /nontemporal_/

surround_mir_test_names memory-legalizer-local.mir local_ ''
surround_mir_test_names memory-legalizer-region.mir region_ ''
surround_mir_test_names memory-legalizer-multiple-mem-operands-nontemporal-1.mir '' '_nontemporal_1'
surround_mir_test_names memory-legalizer-multiple-mem-operands-nontemporal-2.mir '' '_nontemporal_2'

llvm/utils/update_llc_test_checks.py "$TESTDIR"/memory-legalizer-{atomic-{cmpxchg,rmw,fence},load,store}.ll
llvm/utils/update_mir_test_checks.py "$TESTDIR"/memory-legalizer-{local,region,multiple-mem-operands-{atomics,nontemporal-{1,2}},atomic-insert-end}.mir
llvm-lit "$TESTDIR"/memory-legalizer*.{ll,mir}
