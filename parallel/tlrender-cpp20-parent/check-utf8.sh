#!/bin/sh
set -eu
root=/home/siraben/i686-iso-work/refresh-20261111
lane="$root/parallel/tlrender-cpp20-parent"
source=/nix/store/gc7x6r2w1lh5hbpbi82a1fdbbp03hg77-source
work="$lane/validation-source"
test ! -e "$work"
mkdir -p "$work/bin/tlplay"
for name in FilesModel.cpp MenuBar.cpp RecentFilesModel.cpp CMakeLists.txt; do
    cp "$source/bin/tlplay/$name" "$work/bin/tlplay/$name"
    chmod u+w "$work/bin/tlplay/$name"
done
patch -d "$work" -p1 < "$root/nixpkgs/pkgs/by-name/tl/tlrender/cpp20-filesystem-utf8.patch"
cmp "$work/bin/tlplay/PathUtil.h" "$lane/source/bin/tlplay/PathUtil.h"
cxx64=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))+"/bin/g++")' "$root/parallel/ocio-numerical-review/compiler64.json")
for width in 32 64; do
    case "$width" in
        32) cxx=/nix/store/49jmbfsrsp9iwilqhqnwi3y7dnlh38rj-gcc-wrapper-16.2.0/bin/g++ ;;
        64) cxx="$cxx64" ;;
    esac
    for standard in 17 20; do
        exe="$lane/utf8-$width-cpp$standard"
        "$cxx" "-std=c++$standard" -O2 -Wall -Wextra \
            -I"$work/bin/tlplay" -I/nix/store/ifa1fa8nw2gwhip4mqb8cy10dx6jaa19-nlohmann_json-3.12.0/include \
            "$lane/utf8-regression.cpp" -o "$exe"
        timeout 30 "$exe"
    done
done
python3 - <<'PY'
import hashlib,json
from pathlib import Path
r=Path('/home/siraben/i686-iso-work/refresh-20261111');lane=r/'parallel/tlrender-cpp20-parent'
(lane/'utf8-passed.json').write_text(json.dumps({'passed':True,'scope':'actual applied private UTF8 helper, not complete application/Windows validation','widths':[32,64],'standards':[17,20],'assertions':['nonASCII including supplementary-plane bytes exact','filesystem roundtrip','menu filename bytes','empty path','recent JSON string roundtrip','legacy C++20 JSON-array negative control'],'patchSha256':hashlib.sha256((r/'nixpkgs/pkgs/by-name/tl/tlrender/cpp20-filesystem-utf8.patch').read_bytes()).hexdigest()},indent=2)+'\n')
PY
