#!/bin/bash

set -o pipefail

p4 revert ...
p4 edit $(cat ~/1.patch | sed -n 's#+++ b/\(.*\)#\1#p')
patch -p1 <~/1.patch
