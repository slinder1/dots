#!/bin/bash

usage() {
  printf "clenv - execute an OpenCL program in a modified environment\n\n"
  printf "usage: %s [-h] [-v] ld-library-path amd-ocl-build-options-append command...\n" \
    "$0" >&2
  printf "\t-h: print help\n"
  printf "\t-v: verbose (AMD_OCL_LOG_LEVEL=3 and AMD_OCL_PRINT_LOG=1)\n"
}

OPTIND=1

while getopts ":v" opt; do
  case "$opt" in
    h|\?)
      usage
      exit 0
      ;;
    v)
      export AMD_OCL_LOG_LEVEL=3
      export AMD_OCL_PRINT_LOG=1
      ;;
  esac
done

shift $((OPTIND-1))
[ "${1:-}" = "--" ] && shift

if [[ $# -lt 3 ]]; then
  usage
  exit 1
fi

export LD_LIBRARY_PATH="$1"; shift
export AMD_OCL_BUILD_OPTIONS_APPEND="$1"; shift

# Do a sanity check that the user-supplied LD_LIBRARY_PATH is meaningful.
libopencl_path=$(ldd "$1" | awk '$1 ~ /^libOpenCL\.so.*$/ { print $3 }')
if [[ ! $libopencl_path = $LD_LIBRARY_PATH* ]]; then
  printf "error: invalid LD_LIBRARY_PATH \"%s\"; default \"%s\" was loaded\n" \
    "$LD_LIBRARY_PATH" "$libopencl_path" >&2
  exit 1
fi

"$@"
