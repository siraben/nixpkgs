#!/bin/sh
set -eu
root=/home/siraben/i686-iso-work/refresh-20261111
lane="$root/parallel/ocio-numerical-review"
cxx32=/nix/store/49jmbfsrsp9iwilqhqnwi3y7dnlh38rj-gcc-wrapper-16.2.0/bin/g++
cxx64=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))+"/bin/g++")' "$lane/compiler64.json")
for variant in gcc-x87 clang-x87 x64-scalar; do
    case "$variant" in
        gcc-x87) base=/nix/var/nix/builds/nix-3726916-4173132065/build/source; cxx="$cxx32" ;;
        clang-x87) base=/nix/var/nix/builds/nix-4128419-1179649009/build/source; cxx="$cxx32" ;;
        x64-scalar) base="$root/opencolorio-x86_64-scalar-result"; cxx="$cxx64" ;;
    esac
    exe="$lane/aces2_forward_boundary_probe.$variant"
    if [ "$variant" = x64-scalar ]; then
        library="$base/lib"
        "$cxx" -std=c++17 -O2 -ffp-contract=on -Wall -Wextra -I"$base/include" \
            "$lane/aces2_forward_boundary_probe.cpp" "$library/libOpenColorIO.so" \
            -Wl,-rpath,"$library" -o "$exe"
    else
        library="$base/build/src/OpenColorIO"
        "$cxx" -std=c++17 -O2 -ffp-contract=on -Wall -Wextra \
            -I"$base/build/include" -I"$base/include" -I"$base/build/include/OpenColorIO" \
            "$lane/aces2_forward_boundary_probe.cpp" "$library/libOpenColorIO.so" \
            -Wl,-rpath,"$library" -o "$exe"
    fi
    loader=$(readelf -l "$exe" | python3 -c 'import re,sys; print(re.search(r"Requesting program interpreter: ([^\]]+)\]",sys.stdin.read()).group(1))')
    LD_LIBRARY_PATH="$library" "$loader" --list "$exe" > "$lane/forward-boundary-$variant-loader.txt"
    for profile in rec709 p3; do
        for input_case in clang-inverse reference-inverse ideal; do
            python3 "$root/run.py" "opencolorio-sdr-boundary-$variant-$profile-$input_case" \
                env "LD_LIBRARY_PATH=$library" timeout 90 "$exe" "$profile" "$input_case"
        done
    done
done
