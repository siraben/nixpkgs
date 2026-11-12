#!/bin/sh
set -eu
root=/home/siraben/i686-iso-work/refresh-20261111
lane="$root/parallel/ocio-numerical-review"
b=/nix/var/nix/builds/nix-4128419-1179649009/build/source
library="$b/build/src/OpenColorIO"
cxx=/nix/store/49jmbfsrsp9iwilqhqnwi3y7dnlh38rj-gcc-wrapper-16.2.0/bin/g++
test -e "$library/libOpenColorIO.so"
# Same GCC public-API caller as earlier controls; only the library compiler varies.
"$cxx" -std=c++17 -O2 -ffp-contract=on -Wall -Wextra \
    -I"$b/build/include" -I"$b/include" -I"$b/build/include/OpenColorIO" \
    "$lane/aces2_public_probe.cpp" "$library/libOpenColorIO.so" \
    -Wl,-rpath,"$library" -o "$lane/aces2_public_probe.i686-clang-x87"
exe="$lane/aces2_public_probe.i686-clang-x87"
readelf -h "$exe" > "$lane/aces2-i686-clang-x87-elf.txt"
loader=$(readelf -l "$exe" | python3 -c 'import re,sys; print(re.search(r"Requesting program interpreter: ([^\]]+)\]",sys.stdin.read()).group(1))')
LD_LIBRARY_PATH="$library" "$loader" --list "$exe" > "$lane/aces2-i686-clang-x87-loader.txt"
python3 "$root/run.py" opencolorio-aces2-public-i686-clang-x87 \
    env "LD_LIBRARY_PATH=$library" timeout 90 "$exe"
