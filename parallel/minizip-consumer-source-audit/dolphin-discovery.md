# Pinned Dolphin discovery seam — parent source audit

Exact fetched Dolphin 2609b source:
`/nix/store/sgnq0hryjqpxd5xhgjry5ykqrw5b42ba-source`.

- `CMakeLists.txt:678–680` calls
  `dolphin_find_optional_system_library_pkgconfig(minizip-ng, ..., MINIZIP::minizip-ng, ...)`.
- `CMake/DolphinLibraryTools.cmake:126–142` uses
  `pkg_search_module(... IMPORTED_TARGET)` for system discovery and aliases
  `PkgConfig::minizip-ng`, rather than reconstructing only include/library paths.
- `DolphinLibraryTools.cmake:6–13` implements that alias through an INTERFACE
  target linking the original imported target. This preserves its public
  compile options, including pkg-config's `_FILE_OFFSET_BITS=64`.
- `Source/Core/Common/CMakeLists.txt:180–186` links minizip PUBLIC into common.
- `Common/MinizipUtil.h:17–35` uses an opaque reader handle and fixed-width
  `u64/u32` byte counts. Its inspected interface does not exchange libc dirent,
  stat or offset objects with minizip.

This resolves the previously unavailable discovery-helper source. It is not
an actual Dolphin package build, comprehensive public-interface audit or
runtime/closure claim. Its public target propagation can reach many Dolphin
TUs; the isolated discovery harness tests that route without force-enabling
or building the application. Both C and C++ high-inode runtime probes and
metadata-derived compile-command assertions now pass:
`parallel/minizip-public-validation/dolphin-discovery-passed.json`.
The initial run passed compilation/runtime but failed evidence collection
because export was enabled after target creation; original work/logs remain.
