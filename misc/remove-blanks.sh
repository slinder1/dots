#!/bin/bash

set -euo pipefail

TMP="$(mktemp)"
trap '{ rm -f "$TMP"; }' EXIT

drop_leading_blank_lines() {
    awk 'NF { printing=1 } printing'
}

for f in llvm/test/CodeGen/AMDGPU/memory-legalizer-*.{ll,mir}; do
    cat "$f" | drop_leading_blank_lines | tac | drop_leading_blank_lines | tac > "$TMP"
    mv "$TMP" "$f"
done
