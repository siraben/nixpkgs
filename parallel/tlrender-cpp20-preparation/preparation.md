# Code Context

## Files Retrieved
Paths below use T=`/nix/store/gc7x6r2w1lh5hbpbi82a1fdbbp03hg77-source`, F=`/nix/store/1bylhb9g2aphmj3a1gha4kld9zkbcqfc-source`, B=`/nix/var/nix/builds/nix-4185821-2138654336/build/source/build`, R=`/home/siraben/i686-iso-work/refresh-20261111`.
1. `T/bin/tlplay/FilesModel.cpp` lines 49–59: failing filesystem-to-tlCore boundary.
2. `T/lib/tlCore/Path.h` lines 48–65: constructors require `std::string`, not `std::u8string`.
3. `B/bin/tlplay/CMakeFiles/tlplay.dir/flags.make` lines 1–9: GCC wrapper 16.2.0; `CXX_FLAGS = -O3 -DNDEBUG`, no explicit `-std=`.
4. `B/CMakeCache.txt` lines 40–63, 402, 498: compiler, flags, OpenTimelineIO 0.18.1 and feather-tk 0.4.0 dependency locations.
5. `F/CMakeLists.txt` lines 46–51: feather-tk sets C++17 for its own build.
6. `F/lib/feather-tk/core/File.cpp` lines 29–45: existing direct `.u8string()` convention, not a conversion helper.
7. `F/lib/feather-tk/core/String.cpp` lines 215–224: toWide/fromWide use codecvt; not a filesystem UTF-8 bridge.
8. `T/bin/tlplay/MenuBar.cpp` lines 79–97 and `T/bin/tlplay/RecentFilesModel.cpp` lines 37–45: two additional `.u8string()` consumers.
9. `T/lib/tlCore/PathWin32.cpp` lines 42–66: established UTF-16/UTF-8 convention.
10. `R/nixpkgs/pkgs/by-name/tl/tlrender/package.nix` lines 56–102: 0.10.0, existing minizip patch and dependencies; inspected feather-tk package too.
11. `R/tlrender-i686-sse2-comparison.log` lines 10542–10558: actual char8_t constructor failure and u8path deprecation warning.

## Key Code / smallest proposed delta
At `T/bin/tlplay/FilesModel.cpp:53` replace only the existing statement with:
```cpp
const auto utf8 = path.u8string();
auto timeline = timeline::Timeline::create(
    context, file::Path(std::string(
        reinterpret_cast<const char*>(utf8.data()), utf8.size())));
```
No additional include should be needed: this translation unit already uses the string-based Path API.
This is an explicit owning byte copy, not a pointer lifetime workaround: char may inspect object representation, and char8_t holds UTF-8 code units. Explicit length avoids truncation. The same code accepts the C++17 std::string result and C++20 std::u8string result. Keep u8string's UTF-16-to-UTF-8 conversion on Windows and UTF-8 bytes on POSIX; do NOT replace it with locale-dependent `.string()`, toWide/fromWide, `-fno-char8_t`, or a lower standard.

## Architecture
FilesModel receives a feather-tk filesystem path, converts it to tlCore's UTF-8 string Path, then constructs Timeline and Player. The API mismatch is C++20 char8_t source incompatibility, not i686-specific, SIMD-related, or minizip file-width ABI evidence.
The tlRender source does not select a CXX_STANDARD in inspected CMake sources; the actual failing target has no `-std=` option and thus uses GCC16's default GNU C++20. Its filesystem and feather-tk dependency imply C++17 as the relevant baseline; feather-tk explicitly builds as C++17 but does not export a cxx_std requirement in the inspected installed CMake files. Installed OpenTimelineIO CMake files also had no cxx_std requirement match. Do not interpret feather-tk's own setting as a propagated application setting.
No existing reusable filesystem-to-UTF8-byte-string utility was found in targeted tlCore Path/File and feather-tk core File/String searches. Their convention is direct u8string use; the wide-string codecvt helpers are neither needed nor a justified portable replacement.

## Additional concrete risk
Fixing FilesModel alone is the smallest repair for the observed diagnostic, not proof tlplay will finish. `MenuBar.cpp:89` supplies u8string to Action::create and likely needs the same byte bridge. `RecentFilesModel.cpp:42` pushes u8string into JSON; nlohmann may serialize this as a numeric array rather than a path string. Parent should inspect/fix these exact boundaries next, potentially sharing a small local helper if touching all three. Avoid broad feather-tk rewrites: its separate C++17 build is not this failing target.

## Targeted regression idea (not executed)
Use explicit UTF-8 bytes `"dir/\xc3\xa9-\xe6\xbc\xa2-\xf0\x9f\x98\x80.mov"`; construct `std::filesystem::u8path(expected)` in C++17/C++20, apply the exact proposed bridge, assert byte equality and that `file::Path(bytes).get()` preserves the path (confirm getter signature when implementing). Also round-trip with u8path and compare native paths. Run on POSIX and Windows, including a supplementary-plane character; on Windows also start from a native wide path containing that filename. Assert recent-files JSON is a string, not an array, and menu labels retain identical bytes if those boundaries are repaired. Empty path is a useful edge case. No file IO or media fixture is necessary for the conversion regression; actual Unicode application open remains separate validation.

## Research limits / Start Here
Open FilesModel.cpp first, then MenuBar.cpp and RecentFilesModel.cpp before declaring the source repair complete. Bounded local duplicate lookup in the exact tlrender and feather-tk Nix package directories found no char8_t/u8string patch. No web/search tool is available; no upstream issue/PR matching claim or author attribution is made. No external code reused. No build, test, compile, integration edit, ref update, or network workaround was performed. Existing Krita success and minizip/OCIO checks remain separate; actual tlRender application/ABI validation is pending.

```acceptance-report
{
  "criteriaSatisfied": [{"id":"criterion-1","status":"satisfied","evidence":"Exact failing target flags and source boundary inspected; minimal byte-preserving delta and Unicode regression proposed."}],
  "changedFiles": [],
  "testsAddedOrUpdated": [],
  "commandsRun": [{"command":"find/read/rg/nl targeted source, generated flags, installed CMake metadata and package audit","result":"passed","summary":"Read-only inspection; initial wrong build-root probes corrected to source/build."}],
  "validationOutput": ["No builds/tests/compiles run; proposed delta only."],
  "residualRisks": ["MenuBar and recent-files JSON are additional C++20 boundaries.","No upstream web lookup available; application/ABI and Windows validation pending."],
  "noStagedFiles": true,
  "diffSummary": "No source changes; preparation artifact only.",
  "reviewFindings": ["FilesModel.cpp:53 passes std::u8string to a std::string constructor under GCC16 default C++20."],
  "manualNotes": "Preserve package features, test selection and CPU baseline; this is not a minizip ABI failure."
}
```
