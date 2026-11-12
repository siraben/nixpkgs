#!/bin/sh
set -eu
root=/home/siraben/i686-iso-work/refresh-20261111
lane="$root/parallel/ocio-numerical-review"
cxx32=/nix/store/49jmbfsrsp9iwilqhqnwi3y7dnlh38rj-gcc-wrapper-16.2.0/bin/g++
cxx64=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))+"/bin/g++")' "$lane/compiler64.json")
result_rc=0
for variant in gcc-x87 gcc-float-store clang-x87 x64-scalar sse2-control; do
    retained=true
    cxx="$cxx32"
    case "$variant" in
        gcc-x87) base=/nix/var/nix/builds/nix-3726916-4173132065/build/source ;;
        gcc-float-store) base=/nix/var/nix/builds/nix-3979934-74014087/build/source ;;
        clang-x87) base=/nix/var/nix/builds/nix-4128419-1179649009/build/source ;;
        x64-scalar) base="$root/opencolorio-x86_64-scalar-result"; retained=false; cxx="$cxx64" ;;
        sse2-control) base="$root/opencolorio-i686-sse2-matched-lfs-result"; retained=false ;;
    esac
    exe="$lane/aces2_sdr_white_probe.$variant"
    if [ "$retained" = true ]; then
        library="$base/build/src/OpenColorIO"
        "$cxx" -std=c++17 -O2 -ffp-contract=on -Wall -Wextra \
            -I"$base/build/include" -I"$base/include" -I"$base/build/include/OpenColorIO" \
            "$lane/aces2_sdr_white_probe.cpp" "$library/libOpenColorIO.so" \
            -Wl,-rpath,"$library" -o "$exe"
    else
        library="$base/lib"
        "$cxx" -std=c++17 -O2 -ffp-contract=on -Wall -Wextra -I"$base/include" \
            "$lane/aces2_sdr_white_probe.cpp" "$library/libOpenColorIO.so" \
            -Wl,-rpath,"$library" -o "$exe"
    fi
    loader=$(readelf -l "$exe" | python3 -c 'import re,sys; print(re.search(r"Requesting program interpreter: ([^\]]+)\]",sys.stdin.read()).group(1))')
    LD_LIBRARY_PATH="$library" "$loader" --list "$exe" > "$lane/sdr-white-$variant-loader.txt"
    for profile in rec709 p3; do
        python3 "$root/run.py" "opencolorio-sdr-white-$variant-$profile" \
            env "LD_LIBRARY_PATH=$library" timeout 90 "$exe" "$profile" || result_rc=1
    done
done
exit "$result_rc"
