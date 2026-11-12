#!/usr/bin/env bash
# COMMAND SUGGESTIONS ONLY. Parent may submit this payload via bg_run in its
# approved i686 tool environment; this lane has not executed it.
set -euo pipefail
: "${PREPARATION:?absolute path to this preparation lane}"
: "${WORK:?fresh parent-owned validation directory}"
: "${NORMAL:?fresh installed patched minizip-ng prefix}"
: "${COMPAT:?fresh installed patched minizip-ng-compat prefix}"
: "${CC:?i686 C compiler executable, not a command containing flags}"
: "${CXX:?i686 C++ compiler executable, not a command containing flags}"
: "${HIGH_INODE_ROOT:?writable parent-approved filesystem with high inodes}"
: "${PKG_CONFIG_DEPS:?colon-separated target dependency lib/pkgconfig directories}"
: "${OCIO_MODULE_DIR:?proposed-patched OCIO share/cmake/modules directory}"
# Supply target dependency CMake prefixes/toolchain through the parent environment.
# Do not supply _FILE_OFFSET_BITS or _TIME_BITS in any C/C++ environment flags.
mkdir -p "$WORK"
if [ -n "${FIXTURE_DIR:-}" ]; then
    fixture=$FIXTURE_DIR
    fixture_file=${FIXTURE_FILE:?existing fixture regular-file basename}
    fixture_subdir=${FIXTURE_SUBDIR:?existing fixture directory basename}
    printf 'using existing read-only fixture: %s\n' "$fixture"
else
    fixture=$(mktemp -d "$HIGH_INODE_ROOT/minizip-installed-abi.XXXXXX")
    fixture_file=abi-file-with-a-distinct-name.txt
    fixture_subdir=abi-subdirectory-with-a-distinct-name
    printf 'installed minizip ABI fixture\n' > "$fixture/$fixture_file"
    mkdir "$fixture/$fixture_subdir"
    printf 'fixture retained for inspection: %s\n' "$fixture"
fi
# The probe rejects a directory inode <= UINT32_MAX; no false low-inode PASS.
for variant in normal compat; do
    if [ "$variant" = normal ]; then
        prefix=$NORMAL; module=minizip-ng; compat=OFF
    else
        prefix=$COMPAT; module=minizip; compat=ON
    fi
    # Deliberately expose only this variant plus target dependency metadata.
    export PKG_CONFIG_PATH=
    export PKG_CONFIG_LIBDIR="$prefix/lib/pkgconfig:$PKG_CONFIG_DEPS"
    pkg-config --modversion "$module"
    pkg-config --cflags --libs "$module"
    grep -n 'INTERFACE_COMPILE_DEFINITIONS' "$prefix/lib/cmake/$module/$module-targets.cmake"
    for discovery in cmake-target pkg-config; do
        build="$WORK/$variant-$discovery"
        cmake -S "$PREPARATION/consumers/$discovery" -B "$build" \
            -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" \
            -DCMAKE_PREFIX_PATH="$prefix;${CMAKE_PREFIX_PATH:-}" \
            -DMINIZIP_COMPAT="$compat" -DMINIZIP_EXPECT_FILE_OFFSET_64=ON
        cmake --build "$build" --verbose
        for language in c cpp; do
            "$build/directory_probe_$language" "$fixture" "$fixture_file" "$fixture_subdir"
        done
    done
    # Independent non-CMake usage. pkg-config token splitting is intentional;
    # paths in these Nix metadata files contain no spaces.
    "$CC" $(pkg-config --cflags "$module") -DEXPECT_FILE_OFFSET_64=1 \
        "$PREPARATION/consumers/common/directory_probe.c" \
        $(pkg-config --libs "$module") -Wl,-rpath,"$prefix/lib" -o "$WORK/$variant-raw-c"
    "$CXX" $(pkg-config --cflags "$module") -DEXPECT_FILE_OFFSET_64=1 \
        "$PREPARATION/consumers/common/directory_probe.cpp" \
        $(pkg-config --libs "$module") -Wl,-rpath,"$prefix/lib" -o "$WORK/$variant-raw-cpp"
    for language in c cpp; do
        "$WORK/$variant-raw-$language" "$fixture" "$fixture_file" "$fixture_subdir"
    done
done
# OCIO's finder expects the normal installed target. This seam test does not
# build OCIO and is not a substitute for inspecting OCIO's own compiler commands.
export PKG_CONFIG_PATH=
export PKG_CONFIG_LIBDIR="$NORMAL/lib/pkgconfig:$PKG_CONFIG_DEPS"
for fallback in OFF ON; do
    build="$WORK/ocio-finder-fallback-$fallback"
    cmake -S "$PREPARATION/consumers/ocio-finder" -B "$build" \
        -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" \
        -DCMAKE_PREFIX_PATH="$NORMAL;${CMAKE_PREFIX_PATH:-}" \
        -Dminizip-ng_DIR="$NORMAL/lib/cmake/minizip-ng" \
        -DOCIO_MODULE_DIR="$OCIO_MODULE_DIR" -DFORCE_PKGCONFIG="$fallback"
    cmake --build "$build" --verbose
    for language in c cpp; do
        "$build/directory_probe_$language" "$fixture" "$fixture_file" "$fixture_subdir"
    done
done
