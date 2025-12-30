#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

next() {
    find /opt/rocm/ -type f -print0 \
        | xargs -r0 dpkg -S 2>/dev/null \
        | awk 'NF == 2 { print $1; exit }' \
        | sed 's/:$//'
}

n="$(next)"
while [ -n "$n" ]; do
    printf "uninstalling: %s\n" "$n"
    sudo apt-get autoremove -y "$n"
    n="$(next)"
done

sudo rm -rf /opt/rocm
