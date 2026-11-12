#!/bin/sh
set -eu
root=/home/siraben/i686-iso-work/refresh-20261111
lane="$root/parallel/minizip-public-validation"
work="$lane/dolphin-discovery-work-retry1"
test ! -e "$work"
read_json() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$1" "$2"; }
cmake_bin=$(read_json "$lane/tools.json" cmake)
pc_bin=$(read_json "$lane/tools.json" pkgconfig)
make_bin=$(read_json "$lane/tools.json" make)
export PATH="$cmake_bin/bin:$pc_bin/bin:$make_bin/bin:$PATH"
export PKG_CONFIG_PATH=
export PKG_CONFIG_LIBDIR="$root/minizip-i686-public-result/lib/pkgconfig:$(read_json "$lane/dependencies.json" pkgConfigDeps)"
export CMAKE_PREFIX_PATH="$(read_json "$lane/dependencies.json" cmakePrefixes)"
python3 - <<'PY'
import os
for key, value in os.environ.items():
    if key.startswith(('CFLAGS', 'CXXFLAGS', 'CPPFLAGS', 'NIX_CFLAGS_COMPILE')):
        assert '_FILE_OFFSET_BITS' not in value and '_TIME_BITS' not in value, (key, value)
PY
cmake -S "$lane/dolphin-discovery-probe" -B "$work" \
    -DCMAKE_C_COMPILER=/nix/store/49jmbfsrsp9iwilqhqnwi3y7dnlh38rj-gcc-wrapper-16.2.0/bin/gcc \
    -DCMAKE_CXX_COMPILER=/nix/store/49jmbfsrsp9iwilqhqnwi3y7dnlh38rj-gcc-wrapper-16.2.0/bin/g++
cmake --build "$work" --verbose
fixture=/nix/var/nix/builds/nix-3558329-1790592233/build/source/build/testdata/configs/context_test1
for language in c cpp; do
    "$work/directory_probe_$language" "$fixture" config.ocio shot1
done
python3 - <<'PY'
import json
from pathlib import Path
lane=Path('/home/siraben/i686-iso-work/refresh-20261111/parallel/minizip-public-validation')
commands=json.loads((lane/'dolphin-discovery-work-retry1/compile_commands.json').read_text())
assert len(commands)==2
for entry in commands:
    assert '-D_FILE_OFFSET_BITS=64' in entry['command'], entry
    assert '_TIME_BITS' not in entry['command'], entry
(lane/'dolphin-discovery-passed.json').write_text(json.dumps({'passed':True,'scope':'pinned Dolphin discovery helper, NOT application build','consumers':2,'ambientFileTimeFlags':False,'commands':commands},indent=2)+'\n')
PY
printf '%s\n' 'PASS: pinned Dolphin discovery helper propagates the public ABI to C and C++'
