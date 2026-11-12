# Code Context

Bounded read-only audit of repository `/home/siraben/i686-iso-work/refresh-20261111/nixpkgs` (task baseline 41c5d4ddddc4). No integration edits, builds, tests, shell environments, fetch realizations, or platform overrides. Read the review and preparation reports. Synthetic metadata probes are not real-consumer acceptance.

## Files Retrieved

Local paths below are relative to that repository; upstream paths are relative to the explicitly pinned repository/tag. Upstream text was inspected in memory via raw.githubusercontent.com and GitHub tree API; no default-branch evidence was substituted.

| Consumer | Pinned evidence/files and lines | Discovery / ABI assessment |
|---|---|---|
| linphone-desktop 6.2.0 | `pkgs/applications/networking/instant-messengers/linphone/linphone-desktop/default.nix:43–54,108–112,138–145` | Raw `MINIZIP_INCLUDE_DIRS` and `MINIZIP_LIBRARIES=minizip`; custom modules removed. These variables alone do not propagate definitions. **Unresolved actual use**, not a confirmed dirent consumer or confirmed required flag repair. Origin raw CMakeLists and src/CMakeLists requests timed out. |
| millennium 3.6.2 | `pkgs/by-name/mi/millennium/package.nix:22–34,43–45,122–133`; SteamClientHomebrew/Millennium@v3.6.2 `scripts/cmake/bootstrap_deps.cmake:79–89`; `src/CMakeLists.txt:64–65,244–248`; `src/util/zip.cc:31–37,49–114,123–166` | **Not a raw-variable bypass at this pin.** Nix sets DISTRO_NIX; source finds minizip-ng and aliases `minizip` to `MINIZIP::minizip-ng`; Millennium links that alias. Definition reaches util/zip.cc through ordinary target usage requirements. Uses opaque reader handles plus `mz_zip_file*` and filename fields; extraction happens inside library. No dirent/off_t boundary found in this inspected file. No focused flag patch indicated. |
| telegram 7.4.1 | `pkgs/applications/networking/instant-messengers/telegram/telegram-desktop/unwrapped.nix:51–60,79–85`; telegramdesktop/tdesktop@v7.4.1 `Telegram/CMakeLists.txt:80–113`; `Telegram/SourceFiles/storage/storage_folder_archive.cpp:14–16,204–212,343–415`; pinned cmake submodule below | Links `desktop-app::external_minizip`. Packaged discovery forwards either MINIZIP::minizip or pkg-config IMPORTED_TARGET; both carry new compatibility metadata. Inspected archive code uses compatibility zip_fileinfo/calendar fields, zipOpenNewFileInZip family, zipWriteInFileInZip and zipClose; Qt performs directory walking. No returned libc dirent in inspected code. Actual packaged branch and compile commands remain a gate. |
| tlrender 0.10.0 | `pkgs/by-name/tl/tlrender/package.nix:54–67,89–108`; `minizip-ng-4.patch:1–10,31–55,57–92`; grizzlypeak3d/tlRender@0.10.0 `lib/tlCore/CMakeLists.txt:42–59`; `lib/tlTimeline/TimelineCreate.cpp:99–118,163–183,206–213,246–253`; `lib/tlTimeline/Util.cpp:26–28,664–750` | Package patch selects normal imported target and explicitly links tlTimeline; tlCore also links target privately. Definition reaches both libraries' compilation, but private linkage does NOT automatically promise propagation through tlCore's public headers. Timeline code uses reader/writer handles and mz_zip_file, including caller-allocated structures. Util includes mz_os.h but inspected source has no mz_os_* calls; header inclusion alone is not dirent exposure. `mz_zip_file` time_t stays narrow, so no new layout change established here. |
| DJV 3.1.1 | `pkgs/by-name/dj/djv/package.nix:24–33,50–65`; pinned upstream CMakeLists path pass | Direct dependencies include tlrender, minizip-ng, OCIO. Bounded pinned CMakeLists pass found no minizip-specific hit. Actual source/API use and transitive public interfaces remain unresolved; dependency list does not prove dirent access or definition delivery. |
| dolphin 2609b | `pkgs/by-name/do/dolphin-emu/package.nix:57–67,106–111`; dolphin-emu/dolphin@2609b `CMakeLists.txt:678–680`; `Source/Core/Common/CMakeLists.txt:180–187`; `Source/Core/Common/MinizipUtil.h:7–10,17–35` | Calls `dolphin_find_optional_system_library_pkgconfig(minizip-ng "minizip-ng>=4.0.4" MINIZIP::minizip-ng …)`; common links resulting target PUBLIC. Inspected helper reads through opaque zip handle with integer buffer lengths. Need inspect discovery-helper implementation to establish CFLAGS forwarding (guessed helper path returned 404); target name alone is insufficient. Bundled Externals/minizip-ng/CMakeLists.txt is not evidence for system discovery. |
| swayimg 5.7 | `pkgs/by-name/sw/swayimg/package.nix:37–45,80–85`; artemsen/swayimg@v5.7 `meson.build:102–112`; `src/formats/krita.cpp:8–11,81–146` | Meson dependency('minizip-ng') feeds declare_dependency(dependencies:[zip,png]); normal metadata seam, expected to propagate flags. Krita code uses opaque memory stream/zip handles and fixed integer sizes, not libc directory entries. Need actual target dependency/compile-command confirmation. |

Telegram's `.gitmodules:38–39` identifies desktop-app/cmake_helpers. Root tree at v7.4.1 pins `cmake` to **7ceca3019b4750d7a5acb2de0faffd523ee14095**. At that exact commit, `external/minizip/CMakeLists.txt:7–25` defines the interface alias, tries shared config MINIZIP::minizip, static config MINIZIP::minizipstatic, then `pkg_check_modules(... REQUIRED IMPORTED_TARGET minizip)` and forwards that target. Its unpackaged branch at lines 29–50 uses raw library locations and would bypass metadata; do not validate the wrong branch.

## Key Code

Millennium pinned source corrects the initial suspicion:

```cmake
# scripts/cmake/bootstrap_deps.cmake:79–89
if(DISTRO_NIX)
    find_package(ZLIB REQUIRED)
    find_package(CURL REQUIRED)
    find_package(minizip-ng REQUIRED)
    # ...
    add_library(minizip ALIAS MINIZIP::minizip-ng)
# src/CMakeLists.txt:244
target_link_libraries(Millennium libcurl minizip nlohmann_json)
```

The public ABI at `/nix/store/vqpdqq029p6rhjxxn7xglbw5lmzxzx9q-source/mz_os.h:166–168` is the special dangerous seam: returned libc dirent pointer. Do not generalize this to all zip handles. `mz_zip_file` exposes time_t, but this candidate does not change time width; off_t/ino_t widening does not by itself change that field.

## Architecture

Imported CMake targets / pkg-config imported targets / Meson dependency objects can transfer the public definition into consuming translation units. Raw include/library strings cannot. That contract also changes the consumer's own libc-facing types in *every* affected TU, not only calls into minizip. In particular Dolphin common PUBLIC linkage can spread the definition widely; tlCore PRIVATE linkage can create a boundary to downstream code. No concrete off_t-based public-interface mismatch was demonstrated in this bounded pass; checking those headers and external callbacks remains necessary before claiming closure-wide safety.

Both tlrender (OCIO option) and DJV can load minizip and OCIO into one process. Expressions use the ordinary shared package arguments, not an intentional private wide variant; this is a good seam, not proof of final closure coherence. Require the same rebuilt libminizip-ng.so.4 across OCIO and direct users. Store-path distinction is not symbol isolation. Compatibility Telegram is a separate discovery/ABI lane and cannot be discharged by normal-mode results.

## Start Here

Open linphone's expression first, then obtain its exact source. It is the highest-priority unresolved metadata-bypass candidate. **Do not add global flags just because its expression contains raw variables:** first establish whether those variables are used and which TUs/API structures cross boundaries. Millennium does not need such speculative repair at this pin.

### Explicit unavailable sources / parent fetch needs

Small evaluation (no realization) resolved:

- `linphonePackages.linphone-desktop.src.outPath`: `/nix/store/3jirni5mn0wqk5z5qfr3cyv59nm7zrpa-source` — absent.
- `tlrender.src.outPath`: `/nix/store/gc7x6r2w1lh5hbpbi82a1fdbbp03hg77-source` — absent.
- `djv.src.outPath`: `/nix/store/6bfr0vnirnmsim0bdp82ab93l31xbx6p-source` — absent.

Parent should fetch/retain those exact package sources under its normal authorization. Linphone origin timed out twice. GitHub mirror BelledonneCommunications/linphone-desktop tag 6.2.0 resolves to tree 51d7e7705005cd3f4c3605c13abc941a7235224d; bounded CMakeLists/zip-filename inspection found no minizip use. Mirror equality to hashed origin was not established; this is NOT a safe/unused verdict. DJV pinned CMakeLists pass similarly does not establish complete absence of source use. An attempted scoped store discovery was refused by the inspection tool; no broad store traversal was performed. Initial eval using nonexistent top-level linphone-desktop failed; corrected scoped attribute succeeded.

### Minimal parent validation gates (suggestions only; not run)

1. In retained exact sources, `rg -n 'mz_os_|mz_zip_|mz_stream_|minizip|unz[A-Z]|zipOpen|off_t|struct dirent|struct stat'` restricted to actual consumer source/public headers and CMake/Meson files. Prioritize linphone, DJV, Dolphin discovery helper, tlCore exported headers. Include vendored/submodule TUs actually built, not default-branch search results.
2. Use approved fresh i686 consumer configurations with compile_commands enabled and no manually injected LFS flags. Inspect commands for Millennium util/zip.cc, Telegram storage_folder_archive.cpp, tlTimeline TimelineCreate.cpp/Util.cpp, Dolphin zip users, swayimg krita.cpp and any discovered linphone/DJV users. Confirm `_FILE_OFFSET_BITS=64`, absence of newly introduced `_TIME_BITS`, selected installed target paths and no bundled fallback. Existing parent metadata checks do not replace this.
3. For metadata-bypass source users that actually need the public contract, prefer linking imported target/forwarding pkg-config Cflags at the owning target. Check any public off_t/stat interfaces and other library callbacks before applying a target-wide definition; do not mechanically make every dependency's flags global.
4. Inspect tlrender/DJV/OCIO runtime closure plus ELF NEEDED/RPATH for one coherent normal minizip output, then exercise actual archive paths on high inodes. No parallel private-wide same-SONAME library. Inspect Telegram compatibility separately.

## Result and residual risks

No concrete additional focused consumer repair is proven by retrieved source. Millennium and Telegram packaged discovery are stronger than the initial expression-only suspicion; tlrender has explicit target repairs already. Linphone source/API use, DJV propagation/public interfaces, Dolphin helper flags, complete source coverage, and real i686 compiler/runtime closure evidence remain gates. No claim of complete consumer ABI safety or generic-i686 OCIO correctness.
