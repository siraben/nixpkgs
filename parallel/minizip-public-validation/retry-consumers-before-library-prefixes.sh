#!/bin/sh
set -eu
root=/home/siraben/i686-iso-work/refresh-20261111
lane="$root/parallel/minizip-public-validation"
prep="$root/parallel/minizip-abi-preparation"
test ! -e "$lane/work-retry1"
mkdir "$lane/work-retry1"
read_json() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$1" "$2"; }
cmake_bin=$(read_json "$lane/tools.json" cmake)
pc_bin=$(read_json "$lane/tools.json" pkgconfig)
make_bin=$(read_json "$lane/tools.json" make)
export PATH="$cmake_bin/bin:$pc_bin/bin:$make_bin/bin:$PATH"
export PREPARATION="$prep" WORK="$lane/work-retry1/consumers"
export NORMAL="$root/minizip-i686-public-result" COMPAT="$root/minizip-compat-i686-public-result"
export CC=/nix/store/49jmbfsrsp9iwilqhqnwi3y7dnlh38rj-gcc-wrapper-16.2.0/bin/gcc
export CXX=/nix/store/49jmbfsrsp9iwilqhqnwi3y7dnlh38rj-gcc-wrapper-16.2.0/bin/g++
export HIGH_INODE_ROOT="$lane/high-inode"
export FIXTURE_DIR=/nix/var/nix/builds/nix-3558329-1790592233/build/source/build/testdata/configs/context_test1
export FIXTURE_FILE=config.ocio FIXTURE_SUBDIR=shot1
export PKG_CONFIG_DEPS="$(read_json "$lane/dependencies.json" pkgConfigDeps)"
export CMAKE_PREFIX_PATH="$(read_json "$lane/dependencies.json" cmakePrefixes)"
export OCIO_MODULE_DIR="$lane/work/ocio-patched/share/cmake/modules"
python3 - <<'PY'
import os
for key, value in os.environ.items():
    if key.startswith(('CFLAGS', 'CXXFLAGS', 'CPPFLAGS', 'NIX_CFLAGS_COMPILE')):
        assert '_FILE_OFFSET_BITS' not in value and '_TIME_BITS' not in value, (key,value)
assert os.stat(os.environ['FIXTURE_DIR']).st_ino > 2**32-1
PY
python3 "$root/run.py" minizip-i686-installed-consumers-high-inode bash "$prep/consumer-commands.sh"
if cmake -S "$prep/consumers/cmake-target" -B "$lane/work-retry1/negative-private-metadata" \
    -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" \
    -DCMAKE_PREFIX_PATH="$root/minizip-i686-matched-lfs-result;$CMAKE_PREFIX_PATH" \
    -DMINIZIP_EXPECT_FILE_OFFSET_64=ON > "$lane/negative-private-metadata-retry1.log" 2>&1; then
    echo 'ERROR: private-wide metadata unexpectedly passed' >&2; exit 1
fi
grep -Fq 'Installed CMake target lacks the public file-offset ABI contract' "$lane/negative-private-metadata-retry1.log"
export PKG_CONFIG_PATH=
export PKG_CONFIG_LIBDIR="$NORMAL/lib/pkgconfig:$PKG_CONFIG_DEPS"
if cmake -S "$prep/consumers/ocio-finder" -B "$lane/work-retry1/negative-original-finder" \
    -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" \
    -DCMAKE_PREFIX_PATH="$NORMAL;$CMAKE_PREFIX_PATH" \
    -Dminizip-ng_DIR="$NORMAL/lib/cmake/minizip-ng" \
    -DOCIO_MODULE_DIR=/nix/store/2ywir6xhl7nlyyayqvgh7f1bxw9pkg59-source/share/cmake/modules \
    -DFORCE_PKGCONFIG=ON > "$lane/negative-original-finder-retry1.log" 2>&1; then
    echo 'ERROR: original fallback unexpectedly carried the ABI flag' >&2; exit 1
fi
grep -Fq 'OCIO pkg-config fallback lost the public compilation flag' "$lane/negative-original-finder-retry1.log"
printf '%s\n' 'Public metadata consumers passed; private metadata and original fallback rejected.'
