#!/bin/sh
set -eu
root=/home/siraben/i686-iso-work/refresh-20261111
lane="$root/parallel/minizip-public-validation"
work="$lane/option-guards"
case ${1-fresh} in
fresh)
    test ! -e "$work"
    mkdir -p "$work/source"
    cp -a --no-preserve=ownership --reflink=always /nix/store/vqpdqq029p6rhjxxn7xglbw5lmzxzx9q-source/. "$work/source/"
    ;;
resume-copy)
    test -d "$work/source"
    cmp /nix/store/vqpdqq029p6rhjxxn7xglbw5lmzxzx9q-source/CMakeLists.txt "$work/source/CMakeLists.txt"
    ;;
*) exit 2 ;;
esac
# Only our independent copy: the store directory itself remains read-only.
test ! -L "$work/source"
chmod u+w "$work/source"
patch --batch --fuzz=0 -d "$work/source" -p1 -i "$root/nixpkgs/pkgs/by-name/mi/minizip-ng/public-file-offset-64.patch"
read_json() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$1" "$2"; }
cmake_bin=$(read_json "$lane/tools.json" cmake)
pc_bin=$(read_json "$lane/tools.json" pkgconfig)
make_bin=$(read_json "$lane/tools.json" make)
export PATH="$cmake_bin/bin:$pc_bin/bin:$make_bin/bin:$PATH"
export PKG_CONFIG_PATH=
export PKG_CONFIG_LIBDIR="$(read_json "$lane/dependencies.json" pkgConfigDeps)"
export CMAKE_PREFIX_PATH="$(read_json "$lane/dependencies.json" cmakePrefixes)"
cc=/nix/store/49jmbfsrsp9iwilqhqnwi3y7dnlh38rj-gcc-wrapper-16.2.0/bin/gcc
# The explicit legacy mode remains configurable. This is a configure-only
# compatibility gate, not a replacement for either shipped 168-test suite.
cmake -S "$work/source" -B "$work/legacy-mode" -DCMAKE_C_COMPILER="$cc" \
    -DMZ_COMPAT=OFF -DMZ_FILE32_API=ON -DMZ_FILE_OFFSET_BITS_64=OFF -DMZ_FETCH_LIBS=OFF \
    -DMZ_PPMD=OFF -DMZ_LIBCOMP=OFF -DMZ_PKCRYPT=OFF \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON > "$work/legacy-mode.log" 2>&1
grep -Fq 'MZ_FILE32_API:BOOL=ON' "$work/legacy-mode/CMakeCache.txt"
grep -Fq 'MZ_FILE_OFFSET_BITS_64:BOOL=OFF' "$work/legacy-mode/CMakeCache.txt"
if grep -q -- '-D_FILE_OFFSET_BITS=64' "$work/legacy-mode/minizip-ng.pc"; then
    echo 'ERROR: legacy mode exported the wide ABI' >&2; exit 1
fi
if cmake -S "$work/source" -B "$work/conflicting-modes" -DCMAKE_C_COMPILER="$cc" \
    -DMZ_COMPAT=OFF -DMZ_FILE32_API=ON -DMZ_FILE_OFFSET_BITS_64=ON -DMZ_FETCH_LIBS=OFF \
    > "$work/conflicting-modes.log" 2>&1; then
    echo 'ERROR: conflicting ABI requests were accepted' >&2; exit 1
fi
grep -Fq 'mutually exclusive' "$work/conflicting-modes.log"
python3 - <<'PY'
import json
from pathlib import Path
r=Path('/home/siraben/i686-iso-work/refresh-20261111')
guards=json.loads((r/'audit/minizip-public-guard-matrix.json').read_text())
assert guards == {'i686-linux':True,'x86_64-linux':False,'i686-linux-musl':False,
                  'aarch64-darwin':False,'armv7l-linux':True}, guards
(r/'parallel/minizip-public-validation/option-guards/passed.json').write_text(
    json.dumps({'legacy_mode_accepted':True,'legacy_mode_exports_wide_flag':False,
                'conflicting_modes_rejected':True,'platform_predicate':guards,
                'arm_runtime_validated':False},indent=2)+'\n')
PY
printf '%s\n' 'PASS: legacy mode preserved; conflicting ABI requests rejected; platform predicate checked'
