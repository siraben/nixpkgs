#!/bin/sh
set -eu
root=/home/siraben/i686-iso-work/refresh-20261111
lane="$root/parallel/minizip-public-validation"
prep="$root/parallel/minizip-abi-preparation"
test ! -e "$lane/work"
python3 "$root/run.py" minizip-i686-public-contract nix-build "$root/nixpkgs" -A minizip-ng --argstr system i686-linux --out-link "$root/minizip-i686-public-result" --keep-failed --keep-going --max-jobs 2 --cores 4 --max-silent-time 900 --option extra-platforms 'i686-linux x86_64-linux aarch64-linux armv7l-linux'
python3 "$root/run.py" minizip-compat-i686-public-contract nix-build "$root/nixpkgs" -A minizip-ng-compat --argstr system i686-linux --out-link "$root/minizip-compat-i686-public-result" --keep-failed --keep-going --max-jobs 2 --cores 4 --max-silent-time 900 --option extra-platforms 'i686-linux x86_64-linux aarch64-linux armv7l-linux'
mkdir -p "$lane/work/ocio-patched/share/cmake/modules" "$lane/high-inode"
cp /nix/store/2ywir6xhl7nlyyayqvgh7f1bxw9pkg59-source/share/cmake/modules/Findminizip-ng.cmake "$lane/work/ocio-patched/share/cmake/modules/"
patch --batch --fuzz=0 -d "$lane/work/ocio-patched" -p1 -i "$root/nixpkgs/pkgs/by-name/op/opencolorio/minizip-pkgconfig-cflags.patch"
read_json() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$1" "$2"; }
cmake_bin=$(read_json "$lane/tools.json" cmake)
pc_bin=$(read_json "$lane/tools.json" pkgconfig)
make_bin=$(read_json "$lane/tools.json" make)
export PATH="$cmake_bin/bin:$pc_bin/bin:$make_bin/bin:$PATH"
export PREPARATION="$prep" WORK="$lane/work/consumers"
export NORMAL="$root/minizip-i686-public-result" COMPAT="$root/minizip-compat-i686-public-result"
export CC=/nix/store/49jmbfsrsp9iwilqhqnwi3y7dnlh38rj-gcc-wrapper-16.2.0/bin/gcc
export CXX=/nix/store/49jmbfsrsp9iwilqhqnwi3y7dnlh38rj-gcc-wrapper-16.2.0/bin/g++
export HIGH_INODE_ROOT="$lane/high-inode"
export PKG_CONFIG_DEPS="$(read_json "$lane/dependencies.json" pkgConfigDeps)"
export CMAKE_PREFIX_PATH="$(read_json "$lane/dependencies.json" cmakePrefixes)"
export OCIO_MODULE_DIR="$lane/work/ocio-patched/share/cmake/modules"
# Do not let an ambient explicit large-file definition make a consumer gate pass.
python3 - <<'PY'
import os
for key, value in os.environ.items():
    if key.startswith(('CFLAGS', 'CXXFLAGS', 'CPPFLAGS', 'NIX_CFLAGS_COMPILE')):
        assert '_FILE_OFFSET_BITS' not in value and '_TIME_BITS' not in value, (key,value)
PY
python3 "$root/run.py" minizip-i686-installed-consumers bash "$prep/consumer-commands.sh"
# Negative control: the old private-wide metadata must be rejected, despite
# using the same target compiler and having a perfectly linkable library.
if cmake -S "$prep/consumers/cmake-target" -B "$lane/work/negative-private-metadata" \
    -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" \
    -DCMAKE_PREFIX_PATH="$root/minizip-i686-matched-lfs-result;$CMAKE_PREFIX_PATH" \
    -DMINIZIP_EXPECT_FILE_OFFSET_64=ON > "$lane/negative-private-metadata.log" 2>&1; then
    echo 'ERROR: private-wide metadata unexpectedly passed' >&2; exit 1
fi
grep -Fq 'Installed CMake target lacks the public file-offset ABI contract' "$lane/negative-private-metadata.log"
# Negative control for the original OCIO fallback dropping PC_CFLAGS_OTHER.
export PKG_CONFIG_PATH=
export PKG_CONFIG_LIBDIR="$NORMAL/lib/pkgconfig:$PKG_CONFIG_DEPS"
if cmake -S "$prep/consumers/ocio-finder" -B "$lane/work/negative-original-finder" \
    -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" \
    -DCMAKE_PREFIX_PATH="$NORMAL;$CMAKE_PREFIX_PATH" \
    -Dminizip-ng_DIR="$NORMAL/lib/cmake/minizip-ng" \
    -DOCIO_MODULE_DIR=/nix/store/2ywir6xhl7nlyyayqvgh7f1bxw9pkg59-source/share/cmake/modules \
    -DFORCE_PKGCONFIG=ON > "$lane/negative-original-finder.log" 2>&1; then
    echo 'ERROR: original fallback unexpectedly carried the ABI flag' >&2; exit 1
fi
grep -Fq 'OCIO pkg-config fallback lost the public compilation flag' "$lane/negative-original-finder.log"
printf '%s\n' 'Public metadata consumers passed; private metadata and original fallback rejected.'
