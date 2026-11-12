# Code Context

## Scope and binding

Read-only continuation bound to integration `d6ff01421387d4963fbc83dc088cddb035f3d395` as supplied, and the uncommitted candidate described by the parent. Previous `audit.md` is preserved. No source edits, builds, tests, shells, fetches, ref changes or publication performed. Source identity/cache verification is parent-provided, not independently rehashed here.

Exact roots (all citations below expand these literal prefixes):
- **L** = `/nix/store/3jirni5mn0wqk5z5qfr3cyv59nm7zrpa-source` (Linphone 6.2.0).
- **T** = `/nix/store/gc7x6r2w1lh5hbpbi82a1fdbbp03hg77-source` (tlRender 0.10.0).
- **D** = `/nix/store/6bfr0vnirnmsim0bdp82ab93l31xbx6p-source` (DJV 3.1.1).
- **N** = `/home/siraben/i686-iso-work/refresh-20261111/nixpkgs`.

## Files Retrieved / focused evidence table

| Exact files and lines | Finding | Smallest necessary repair |
|---|---|---|
| `N/pkgs/applications/networking/instant-messengers/linphone/linphone-desktop/default.nix:108–129,141–145`; `L/CMakeLists.txt:240–261`; `L/external/CMakeLists.txt:1–7`; `L/Linphone/CMakeLists.txt:8–22` | Nix passes raw MINIZIP variables, but also `LINPHONE_QT_ONLY=ON`. Root explicitly skips `add_subdirectory(external)` in that mode; therefore bundled SDK/Google targets are not built by this package. App discovery uses Mediastreamer2, LinphoneCxx, BCToolbox and LibLinphone targets. Full exact-tree case-insensitive minizip/API-name verification produced **no hits**. Raw MINIZIP variables have no source consumer here; this is stale configuration, not a demonstrated raw-variable ABI bypass. | **None required for this desktop's minizip contract.** Optional stale input/flag cleanup is unrelated and not proposed as necessary. Separately packaged SDK libraries are not proved safe by this result. Do not inject a desktop-global LFS flag. |
| `T/CMakeLists.txt:123–126`; `T/lib/tlCore/CMakeLists.txt:32–43,58–74`; `N/pkgs/by-name/tl/tlrender/minizip-ng-4.patch:1–55` | Existing package patch selects normal `MINIZIP::minizip-ng`. tlCore links it PRIVATE, so definition reaches all tlCore compilation (including Unix directory walking), but is not itself a public promise through tlCore. No new fix follows solely from PRIVATE linkage. | Existing patch suffices for the discovered target seam; no additional PUBLIC promotion demonstrated necessary. |
| `T/lib/tlCore/FileInfoUnix.cpp:9–20,26–45,49–67`; `T/lib/tlCore/FileInfo.h:35–69`; `T/lib/tlCore/FileInfoInline.h:29–32` | FileInfo uses explicit `stat64` on non-Apple platforms and **local libc** `opendir/readdir/closedir`. Returned `dirent` is dereferenced in the same TU that calls libc; it does not come from minizip. Public object exposes/stores `uint64_t` size, `int` permissions, `time_t` timestamp and its own Path/Type, not stat/dirent/off_t. Header sweep across T/lib found no off_t/ino_t/stat/dirent/fpos_t/FILE-pointer interface matches; the time_t matches are these FileInfo members. | No concrete FileInfo ABI repair. `_FILE_OFFSET_BITS=64` changes local libc selection coherently; **time_t remains 4 bytes on 32-bit**, not a time64 transition. |
| `T/lib/tlTimeline/TimelineCreate.cpp:99–140,163–183,206–213,246–253`; `T/lib/tlTimeline/Util.cpp:665–750`; `T/lib/tlTimeline/Util.h:84–86,128–136`; `N/pkgs/by-name/tl/tlrender/minizip-ng-4.patch:47–92` | Concrete minizip users: reader create/open/locate/entry-info/read/close/delete; writer create/open/set-compression/add-buffer/add-file/close/delete. Reader gets `mz_zip_file*`; writer allocates and zeroes `mz_zip_file`. No mz_os directory call, minizip callback registration or cross-boundary libc dirent dereference found. Existing patch updates create signatures and explicitly links tlTimeline to normal imported target using plain target_link_libraries signature, which is transitive. Public writeOTIOZ takes strings and OTIO object; memory-read interface uses feather_tk::InMemoryFile. | Retain existing package patch; no additional minizip-specific repair established. External feather-tk interface audit remains a separate gate below. |
| `D/CMakeLists.txt:38–48`; `D/lib/CMakeLists.txt:1–2`; `D/lib/djvApp/CMakeLists.txt:182–183`; `D/bin/djv/CMakeLists.txt:9–18`; `D/cmake/Modules/djvPackage.cmake:442`; `N/pkgs/by-name/dj/djv/package.nix:24–39,50–65` | DJV discovers tlRender, builds djvResource/djvApp and executable, links djvApp to tlRender::tlTimelineUI and tlRender::tlDevice. Full exact-tree minizip/API verification found **only a license-install path**, no direct minizip API/discovery use. Source/public-header scan found no off_t/stat/dirent/FILE-pointer ABI seam. minizip in Nix buildInputs alone does not give flags and does not establish a missing repair. | None directly in DJV. Definition has a source-level transitive route via tlTimelineUI -> tlTimelineGL -> patched tlTimeline -> minizip. Actual exported targets/compile commands still need confirmation. |
| `T/lib/tlTimelineUI/CMakeLists.txt:36`; `T/lib/tlTimelineGL/CMakeLists.txt:17`; `T/lib/tlTimeline/CMakeLists.txt:51–54` plus package patch above | PUBLIC tlTimelineUI links tlTimelineGL; plain-signature tlTimelineGL links tlTimeline; patched plain-signature tlTimeline links minizip. This explains expected DJV definition propagation, rather than assuming propagation from its dependency list. | No global flags warranted. |

## Key Code

```cmake
# L/CMakeLists.txt:240–247
if(NOT APPLE OR MONO_ARCH)
    if(NOT LINPHONE_QT_ONLY)
        function(add_external)
            set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)
            add_subdirectory("external")
        endfunction()
        add_external()
    endif()
```

```cpp
// T/lib/tlCore/FileInfoUnix.cpp:54–60
DIR* dir = opendir(!path.empty() ? path.c_str() : ".");
if (dir)
{
    const struct dirent* de = nullptr;
    while ((de = readdir(dir)))
    {
        const std::string fileName(de->d_name);
```

This is not the dangerous `mz_os_read_dir` seam: libc allocation and dereference use the same compilation mode. Opaque zip handles likewise are not returned libc dirent pointers. `mz_zip_file` timestamps do not change width under this candidate.

## Architecture

Linphone's packaged Qt-only app consumes separately built SDK targets, not the bundled SDK subtree. Its raw MINIZIP cache entries are unused at this pin. DJV consumes tlRender targets, not minizip directly. Existing tlRender patches establish imported-target compilation for both tlCore and archive-implementing tlTimeline; the latter's transitive linkage provides an expected definition route to DJV. tlCore's own inspected public FileInfo interface does not expose a width-changing libc type.

No concrete new PUBLIC off_t/stat/dirent or minizip callback mismatch was found in these exact trees. This is a bounded source conclusion, not closure-wide ABI certification.

## Start Here / remaining gates

1. **External feather-tk ABI is not closed by these three sources.** tlCore publicly depends on `feather-tk::feather-tk-core` (`T/lib/tlCore/CMakeLists.txt:42,59`); tlTimeline Util publicly includes `feather-tk/core/FileIO.h` and uses InMemoryFile (`T/lib/tlTimeline/Util.h:9,84–86`). Check the separately pinned feather-tk FileIO types/callbacks and any other external interfaces compiled narrow versus newly wide clients. No concrete mismatch is asserted without its exact headers. This is the first useful next source inspection, not a reason for speculative global flags.
2. Inspect actual fresh i686 compile commands/exported imported targets: tlCore FileInfoUnix.cpp, tlTimeline TimelineCreate.cpp/Util.cpp, DJV App.cpp. Require metadata-derived `_FILE_OFFSET_BITS=64`, no newly added `_TIME_BITS`, correct patched normal target, no bundled fallback. No such builds were run here.
3. Confirm one coherent normal minizip shared object through tlRender/DJV/OCIO ELF NEEDED/RPATH/runtime closure. Actual archive/read/write and high-inode directory behavior remain consumer runtime gates; parent library/installed-consumer fixture results do not replace them.
4. Linphone's separate SDK dependency builds and their external interfaces remain outside this desktop-source finding. Do not mistake stale desktop variables for evidence about those libraries.
5. Dolphin helper remains unresolved: bounded local refresh-root filename lookup found no retained Dolphin source/helper. No network lookup or broad store traversal was undertaken; this does not weaken the exact-source priorities above. Millennium/Telegram prior packaged-path findings are preserved, not repeated.

## Result

**No additional focused repair is proven necessary in Linphone desktop, DJV or tlCore by these exact sources.** Keep the existing tlRender API/target patch and the parent public minizip metadata candidate. Do not add dependency-presence-driven global flags or promote tlCore linkage solely on speculation. External-header audit, real compiler propagation and runtime closure gates remain open. No broad actual-consumer build success is claimed.

```acceptance-report
{
  "criteriaSatisfied": [{"id":"criterion-1","status":"satisfied","evidence":"Exact-source table resolves stale Linphone variables and DJV direct use; tlCore public types and local directory ABI distinguished; remaining gates explicitly bounded."}],
  "changedFiles": ["parallel/minizip-consumer-source-audit/audit-exact-sources.md"],
  "testsAddedOrUpdated": [],
  "commandsRun": [{"command":"bounded find, rg and numbered source reads of the three supplied store roots and package expressions","result":"passed","summary":"Read-only evidence gathered; no package builds or tests."}],
  "validationOutput": ["Linphone full-tree minizip/API scan: no matches; DJV: license path only.","tlCore public FileInfo uses uint64_t and unchanged time_t; no public libc directory/stat/off_t seam identified."],
  "residualRisks": ["Separate feather-tk and SDK interfaces not fully audited.","Actual i686 compile commands, exported targets and runtime closure/archive gates remain unrun.","Dolphin helper remains unresolved."],
  "noStagedFiles": true,
  "diffSummary": "New report only; previous audit and source trees untouched.",
  "reviewFindings": ["No additional concrete source repair established in the three exact consumer trees."],
  "manualNotes": "Source identities and integration binding supplied by parent; no independent fetch/hash or git-state verification performed. noStagedFiles denotes no staging by this run."
}
```
