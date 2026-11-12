# i686 desktop and package repair report

Status: **in progress**. Pinned upstream: `a238bac4849a79e151329cdc51638d3bc7627c6c`.
Integration: `siraben/i686-xfce-refresh-20261111` in `siraben/nixpkgs`.

## Verified Xfce deliverable

- Full 2.4 GiB ISO built (`xfce-attempt7.json`, exit 0).
- ISO directory: `/nix/store/8a9z6yyv0256qagdl3xcgclhmbmnvswh-nixos-xfce-26.11pre-git-i686-linux.iso`.
- SHA256 recorded in `SHA256SUMS`.
- BIOS/QEMU TCG live boot, i686 architecture, Xorg, Xfce session/panel/desktop
  and terminal verified (`test-xfce-live/live-passed.json`).
- Offline installation to a new disk completed, including GRUB. The harness's
  30-minute deadline expired just before the success marker; its failure is
  retained in `xfce-offline-install.log`, not reported as a clean harness pass.
- A separate disk-only boot without the ISO succeeded; installed hostname,
  ext4 root, i686 architecture, and stable Xfce processes/terminal verified
  (`test-xfce-install/installed-passed.json`, `xfce-installed-disk-boot.json`).
- No physical hardware, UEFI, ARM, or all-services-clean validation claimed.

## Fix inventory

Focused branches use `siraben/i686-<slug>-20261111`, with drafts under
`prs/<slug>/pr.md`. Builds generally used the complete integration stack;
focused branches are not claimed to build independently of dependency fixes.

| Package/component | Repair | Evidence/limits | Slug |
|---|---|---|---|
| iniparser | Enable Unity 64-bit integer assertions in runner and private test library | Both i686 CTest suites; x86_64 unchanged | iniparser |
| rsync | Match large-file ABI in security test preload hook | Security regression passes; x86_64 unchanged | rsync |
| xfsprogs | Backport stale-declaration and int64_t-delta fix | Builds/version checks on both architectures | xfsprogs |
| upower | Remove obsolete i686 battery-test patch | 97 tests and three udev checks; x86_64 unchanged | upower |
| azurite | Use existing JavaScript TypeScript compiler on 32-bit build hosts | Both builds/version checks | azurite |
| msgspec | Correct integer lookup narrowing and MessagePack length overflow; portable timestamp tests | 5834 passing tests on each architecture | msgspec |
| bcachefs-tools | Widen time_t magnitude before Duration::from_secs | Both builds/version/udev checks | bcachefs-tools |
| apache-orc | Match uint64_t count type in std::min | Both builds | apache-orc |
| rapidjson | SSE floating-point flags on i686 | Three CTest targets including Valgrind; existing PR #534793, not a duplicate | carried existing PR |
| isa-l | Correct benchmark size_t output pointers | Both builds; all 17 i686 tests | isa-l |
| google-cloud-cpp | Allow four-nanosecond rounding in four limiter assertions | 521 enabled CTest targets on each architecture | google-cloud-cpp |
| Linux TCP_AO config | Avoid unavailable option on 32-bit | Config and full kernel builds; existing PR #558908 with author credit | carried existing PR |
| pandas | Copy Arrow int32 join labels before in-place null handling | Eight join/sort cases on each architecture; optional full pandas suite not run | pandas |
| Dask | Portable integer fixtures/repr/memory budgets; extend existing categorical xfail; one 1.49 GiB allocation exclusion | i686 16041 passed; x86_64 16056 passed; requires pandas fix | dask |
| afdko | Exclude one exact-output overlap test on i686 | 1500 i686 and 1531 x86_64 tests pass; underlying 0.01 coordinate precision difference remains | afdko |
| Linux development output | Retain architecture Makefile fragments for external modules | Linux 6.18.63 and ZFS 2.4.4 build on both; zfs.ko.xz present; not host-loaded | kernel-dev |
| Shiboken6 generator | Match std::array's size_t extent type | Both builds; no feature removal | shiboken6-generator |
| Qt Multimedia | Complete existing i686 scalar fallback for Resonance Audio | Both builds; non-i686 branch unchanged | qtmultimedia |
| liborcus | Allow one double epsilon of relative error in numeric-parser test | All 59 tests pass on each architecture; no runtime change | liborcus |
| Qt6 qtbase/qmake | Enable private large-file ABI for raw stat calls | Both builds; installed qmake fixes exact 7066-byte/high-inode reproduction | qt6-qmake |
| Qt5 qtbase/qmake | Enable private bootstrap large-file ABI, avoiding inode-overflow enumeration failures | Full builds on both widths; readdir64/stat64 imports and project discovery checked | qt5-qmake |
| yaml-cpp | Backport upstream uint64_t Dragonbox significand fix, preventing wrong serialized magnitudes | Full builds/CTest pass on both widths; 15-case i686 runtime reproducer passes | yaml-cpp |
| gavl | Select 64-bit glibc time ABI on 32-bit, matching int64_t HTTP timestamps | Both builds; 1969/1970/2040 HTTP date round trips pass on each width | gavl |
| PySide6 | Omit optional unavailable WebEngine/WebView modules using availableOn | Both builds and offscreen widget renders; full i686 LXQt system builds | pyside6 |
| PyQt6 | Default optional PDF bindings to QtWebEngine host availability | Both builds/imports/offscreen renders; PDF modules absent on i686 and present on x86_64; integration d6ff01421387, focused 9c2686c4f13c pushed | pyqt6 |
| minizip-ng | Public wide-file ABI on 32-bit GNU/Linux, including normal/compat metadata | 168 tests each; 16 installed consumers, negative controls and option guards; x86_64 derivations unchanged; integration 1bfa643c7119, focused 33c29fc6802c pushed; coordinated ABI rebuild required | minizip-ng |
| OpenColorIO filesystem discovery | Preserve minizip CMake/pkg-config usage requirements | Both i686 discovery paths pass 10 CTests (SSE2 comparison only); production x86_64 passes 10; no CPU/math/check-selection change; integration 883f6d3b3af9, focused 2939057da7a3 pushed | opencolorio-filesystem |
| Graphical installer | Avoid unavailable QEMU guest agent/Firefox on 32-bit, use Dillo | Full ISO and live Xfce boot | graphical-base |
| Hyper-V installer/hardware profiles | Do not require unavailable Hyper-V modules on i686 | Full ISO; x86_64 kernel/initrd/service derivations unchanged | hyperv |

Earlier alsa-firmware (#575089) and marshmallow (#575094) fixes were merged
upstream before this pinned base; they are historical work, not new fixes in
this stack. ARM validation was not established for those changes.

## Expanded substantial-software survey

| Target | Observed result | Next action |
|---|---|---|
| MATE desktop NixOS system and live ISO | **Build and BIOS/QEMU live desktop boot passed**: i686, Xorg, session/panel/Caja, terminal, stability and screenshot | No new MATE-specific fix needed; no installed MATE boot claim |
| GIMP 3.2.6 | Build and version invocation passed | No new fix needed; no interactive runtime claim |
| Inkscape 1.4.4 | Build and headless SVG-to-PNG export passed | No new fix needed; no interactive runtime claim |
| LXQt desktop NixOS system and live ISO | **Full builds and BIOS/QEMU live desktop boot passed**: i686, Xorg, session/panel/PCManFM-Qt, QTerminal, stability and screenshot | Three new dependency fixes; no installed LXQt boot claim |
| LibreOffice 26.8.0.3 | Earlier x86_64 baseline full build/checks pass; new font-repair x86_64 regression running. Actual i686 source font-cache/driver repairs pass Writer 87 and embedding 3 tests; 35 other CppUnit failures plus UNO remain | No successful i686 package or CPU-baseline change claimed |
| Krita 6.0.4.1 | PyQt6/qmake, Qt5 bootstrap, gavl and yaml-cpp repairs validated; remaining OpenColorIO dependency has filesystem/ABI and generic-x87 accuracy defects under investigation | Finish OpenColorIO acceptance before claiming a Krita build |
| RawTherapee 5.13 | **i686 build and headless 16-bit TIFF → JPEG conversion passed**; output verified as 64×64 sRGB JPEG | No new fix needed; no interactive GUI claim |
| digiKam 9.1.0 | Upstream requires QtWebEngineWidgets unconditionally; no demonstrated packaging-only bypass | Recorded as upstream dependency/porting limitation, not fixed by lying about platforms |

Logs: `survey-*-i686.{json,log}` and `trace-{lxqt,libreoffice}-i686.log`.
MATE runtime evidence: `parallel/desktop-validation/test-mate-live/live-passed.json`,
serial log and `live-mate.png` (visually reviewed). Its live ISO is
`/nix/store/4v5szsrvw6200gyvyd0k15gxgajwlk7h-nixos-mate-26.11pre-git-i686-linux.iso`.
The guest had restricted networking. LXQt's first two runs exposed harness
errors: process argv used `/run/current-system/sw/bin/`, and QTerminal did not
support the test's `--title` argument. Both failed runs are preserved; no
package workaround was added. After correcting those test assumptions, strict
session/terminal/stability checks passed, and the terminal screenshot visibly
shows `i686`.

LXQt evidence: `parallel/desktop-validation/test-lxqt-live-retry2/live-passed.json`,
serial log and visually reviewed `live-lxqt.png`. Its live ISO is
`/nix/store/x6jrvj7a0k6w77ycj535bpc9q70fab06-nixos-lxqt-26.11pre-git-i686-linux.iso`.
LibreOffice and application builds continue independently. Application preflight
and digiKam upstream-source evidence: `parallel/kde-apps/REPORT.md`.

RawTherapee conversion evidence: `rawtherapee-i686-image-smoke.{json,log}` and
`audit/rawtherapee-{input.tif,output.jpg}`. HOME/config/cache were isolated to
the test directory. An earlier unsupported `-v` invocation exited with help;
that harness mistake is preserved and is not treated as a package failure.

The survey does not establish that every supported 32-bit application works.
OpenJDK's bootstrap limitation is already tracked in #314873 and open PR
#575087 (metadata restriction, not a working bootstrap). No duplicate PR made.

## Style and idiom audit (ongoing)

- All 30 changed Nix files, including pending dependency repairs and LibreOffice, pass `nixfmt --check`
  (`audit/format-check-final.json`).
- Backup integration ref: `backup/i686-before-expanded-audit-20261111`;
  pre-amend branch hashes: `audit/pre-amend-refs.txt`.
- Review sources: `pkgs/README.md` patch guidelines, `CONTRIBUTING.md`, stdenv
  substitution documentation, current package patterns and selected merged PRs.
- Manual per-fix review and concrete merged-PR/package examples are recorded
  in `audit/style-review.md` (including merged #570857, #553854, #565303).
- Three style amendments autosquashed: iniparser separation, Hyper-V's existing
  platform alias, and xfsprogs converted to a pinned upstream fetchpatch as
  required by `pkgs/README.md`. The fetched patch builds on both architectures;
  backups and `audit/autosquash-range-diff.txt` preserve the before/after.
- The google-cloud-cpp patched test source passes upstream `.clang-format`
  formatting with clang-format 21.1.8 without further changes.
- Keep precise substitutions, host/build distinctions, availability checks for
  optional dependencies, and documented test limits.
- Per-fix conclusions and merged-PR examples are recorded in the style review.
  All focused branches remain single commits on BASE and match recorded remote
  verification. Rapidjson and TCP_AO original author metadata is preserved.
- Three amended focused branches are pushed and verified with exact old-hash
  leases; others retain their already-published focused commits because their
  trees did not change. Integration was rebased and pushed. Mapping is in
  `audit/focused-amendments.json`.

| Amended branch slug | New focused commit | Reason |
|---|---|---|
| iniparser | `aede8099bcc0b83128df71a0084a29d7129c30a7` | Conventional attribute separation |
| hyperv | `04553e3698b2ca0ea55df7b0522a0abb54769f2b` | Reuse local platform alias |
| xfsprogs | `d09640bf66606e15b7555f77ea4881557e3aa0ac` | Fetch published pinned upstream patch |

Pending LibreOffice changes still require full validation, commits and a final
style pass. `libreoffice-i686-attempt6` compiled/linked production code but failed
checking: 38 reported CppUnit failures across 18 CppUnit targets, a test compile
type mismatch, and UNO test failure. Numeric failures include x87 rounding,
integer-vs-sal_Int32 assertion type, impossible 64-bit map fixtures on 32-bit,
and a sw_uiwriter allocation error. This is not a successful package build.
Details: `failures/libreoffice-attempt6-tests.json`.

Attempt 7 fixes the two impossible map fixtures and test-compilation type error,
but still reports 36 CppUnit failures, UNO test failure, and ends on the
900-second silent timeout while sd_export_tests is processing embedded fonts.
Failures include Calc autofill returning its 1.7e307 sentinel and a Writer
allocation error; these are not all being dismissed as harmless rounding.
Details: `failures/libreoffice-attempt7-tests.json` and retained test logs.

`libreoffice-sse2-comparison.nix` is a diagnostic override, not a change to the
generic package. Its first build aborted in HelpIndexer with a double-free
while generating the sbasic/en-US help index, before reaching the comparison
checks. Therefore it has not established that SSE2 resolves the numerical
failures. SSE2 would raise the CPU requirement if adopted; no such support
claim or commit has been made. The independent x86_64 build succeeded,
including its full unitcheck/slowcheck phase (39m17s). Evidence:
`libreoffice-x86_64-comparison.{json,log}` and `libreoffice-x86_64-result`.
The crash reproduces on a copied dataset: GDB shows SIGABRT during SAL's
UTF-8 file-URL-to-system-path conversion, reached from HelpIndexer file reading;
this is memory corruption, not a numeric assertion (`libreoffice-help-indexer-backtrace.log`).
That backtrace identifies the detection site, not necessarily the original
corrupting write. A small C-ABI probe performs 100 regular-file URL open/close
operations successfully against both generic-x87 and SSE2 SAL libraries;
the help-indexer crash has not been reduced to all SAL URL conversions.
See `parallel/lo-help-diagnosis/file-url-regular-file-results.json`.

A separate Clang diagnostic explicitly sets `-march=i686`: the compiler's
normal i686-target default is Pentium 4, so merely switching compilers would
silently introduce SSE2. Preprocessor/driver checks confirm the explicit
variant defines i386/i686 but no SSE macros. It reaches checking but still
reports 21 CppUnit failures (versus 36 in the GCC/standard-precision attempt),
including a Writer allocation failure and embedded-font export failure, then
hits the same 900-second silent timeout. It also exposes Clang-specific test
commands treating unused linker arguments as errors. Neither compiler choice
alone establishes a correct i686 package. This diagnostic is not committed as
the generic implementation. Details:
`failures/libreoffice-clang-i686-comparison-tests.json`. The prior Xfce artifact is validated as built, not claimed byte-for-
byte identical to an ISO embedding the subsequently amended Nixpkgs source.

### Writer allocation: duplicate font mappings, not an oversized document

GDB now locates `testTdf130680`'s failure in a 1 MiB reserve by
`comphelper::UNOMemoryStream`, during Cut's embedded-object copy. Both isolated
GCC and Clang processes have about 4,193,000 KiB virtual size but only
238,000–241,000 KiB resident, with unlimited RLIMIT_AS. Three Noto CJK TTC files
are mapped 84–85 times in total, consuming over 3 GiB of virtual address space.
The fixture itself is only 97,412 bytes. This does not justify excluding it as
an inherently impossible 32-bit test.

A diagnostic HarfBuzz interposer retains one blob per filename: the unchanged
test passes under both compilers (`OK (1)`), with 55 files, 825 calls and 770
cache hits. This is causal diagnostic evidence, **not a production interposer
or completed package repair**. A source candidate uses the existing
reference-counted `FreetypeFontFile` mapping for ordinary HarfBuzz faces as well
as descriptor-backed fonts, with the old file-loading fallback on mapping
failure. The actual i686/GCC VCL source now recompiles and links in an independent
reflink copy; the unchanged Writer regression and the full 87-test sw_uiwriter3
suite pass without the interposer. Full unitcheck/slowcheck still fails, with
35 CppUnit failures across 16 targets plus UNO failure; this is not a successful
LibreOffice package. The first setup attempt stopped while copying eight
unreadable generated SdiTarget headers, a harness/permissions issue. Original
permissions/evidence stayed untouched; make could regenerate missing generated
inputs in the independent copy. Evidence:
`parallel/lo-font-cache-validation/{stage-status.tsv,build/}` and
`failures/libreoffice-font-cache-recheck-tests.json`.
Evidence: `parallel/lo-writer-diagnosis/{font-mapping-summary.json,results-*-run-sharedblob1/}`.
Current upstream has renamed this code to `GenericFontFace.cxx` and still calls
`hb_blob_create_from_file` per face; the local candidate targets packaged 26.8.

The embedded-font timeout also has a concrete integration defect: configure
prefers `makeotfexe`, but AFDKO 5.0.1's entry point unconditionally exits 1 with a
migration notice. The supported `makeotf` driver succeeds on copied artifacts
with identical normalized results in eight bounded comparisons. A configure
candidate is now applied to configure. Editing its generated header initially
did not trigger caller recompilation, so the first zero-exit make was not
sufficient validation. The forced caller rebuild now really compiles/links
`embeddedfontsafdko.cxx`, and a binary-path check confirms the supported driver.
The unchanged embedded-PDF font regression passes (6.7 seconds in the test body,
versus the previous focused timeout), as do all 87 Writer tests and all three
font-embedding tests. Evidence: `lo-supported-font-driver-recheck.{json,log}` and
`parallel/lo-font-cache-validation/driver-stage-status.tsv`. Full x86_64 package
regression validation of the new source changes is being prepared.
The focused EOT invocation also initially used the wrong CppUnit target. The
correct `sd_font_embedding_tests` suite passes all three tests under GCC both
before and after the mapping repair; the previously observed EOT decompression
failure is in the Clang comparison and is not claimed fixed.

## Newly diagnosed Krita dependencies

- **yaml-cpp 0.9.0:** a real double-serialization defect, not a tolerance issue.
  Dragonbox's 64-bit significand is narrowed to 32-bit size_t. For example,
  binary-exact 1.23455810546875 becomes 1.270590651e-05. Backport merged upstream
  PR #1401; keep exact existing assertions. A standalone 15-case i686/x87
  reproducer passes with that upstream patch. Full package builds and CTest
  pass on both architectures; individually committed as 7cd7debb39f4.
- **Qt5/Qt6 qmake:** inode overflow, not file size. Tiny files/directories on
  the build filesystem have inode numbers above UINT32_MAX. Qt6 raw stat fails
  installing files; Qt5 bootstrap readdir truncates project discovery. Minimal
  probes confirm private large-file tool flags fix both without changing public
  QtCore ABI. Qt5 builds now pass on both widths; its installed i686 qmake
  imports readdir64/stat64 and passes directory project discovery. Separate
  commit: 2941d121d546. Qt6 builds also pass on both widths (41c5d4ddddc4):
  installed qmake changes a 7066-byte/inode-4297357119 installation from exit 3
  with EOVERFLOW to exit 0 with matching contents. Evidence:
  `audit/qt6-qmake-install-regression/passed.json`. Upstream Gerrit duplicate checking was
  blocked by HTTP 403; do not claim a comprehensive upstream search.
- **gavl:** HTTP API uses int64_t but gmtime_r expects native time_t. Select
  glibc's 64-bit time ABI on 32-bit. Both builds and HTTP dates before 1970
  and after 2038 pass; individually committed as 8f47126e691a. Public headers
  expose no libc time/stat structs; the HTTP API retains int64_t.
- **PyQt6:** optional PDF default follows QtWebEngine availability. Builds
  against repaired qmake now pass on both widths, as do imports and offscreen
  text/widget PNG renders. PDF/PDFWidgets modules are absent on i686 and present
  on x86_64. Committed as d6ff01421387; focused 9c2686c4f13c and integration
  are pushed and remote-verified. This does not restore PDF on i686.
- **OpenColorIO:** an existing i686 SSE2 repair is proposed in Nixpkgs #536904;
  do not duplicate it. Both that approach and the supported `OCIO_USE_SIMD=OFF`
  scalar backend are being checked with CPU/Python tests explicitly enabled.
  The scalar comparison compiles but fails checks, including numeric assertions,
  a CPU-test segfault and six Python missing-file errors. The named LUT files
  actually exist; lookup/hash code calls narrow `stat`. A 4505-byte CLF has
  inode 4303518631: an i686 probe confirms `stat` fails with EOVERFLOW while
  `stat64` succeeds. This establishes a separate large-inode defect; the
  library's large-file repair is not yet validated. Evidence:
  `audit/opencolorio-inode-probe.{c,txt}`. The SSE2 proposal likewise compiles
  but fails enabled checks (8 of 10 CTest entries, including missing-file CPU
  failures/segfaults and six Python errors). This does not refute its intrinsic
  build fix; it does not address the independent filesystem defect. The
  unmodified x86_64 comparison passes all 10 CTest entries. Both scalar
  large-file comparisons now complete all 1141 CPU cases without the earlier
  segfaults, and all 398 Python tests pass. CPU checking still fails in 114
  cases with 686 assertions; explicitly adding standard excess-precision
  semantics gives exactly the same counts and is not adopted as a fix.
  Of these assertions, 666 use direct equality and 20 use other numerical
  conditions. A small x87 probe demonstrates that raw `double == literal`
  can differ from typed/materialized operand equality without changing nominal
  values or tolerances. The x86_64 scalar control passes all three CTest entries,
  confirming the scalar backend is viable on the comparison architecture. The
  first typed-equality candidate failed compilation because passing integer
  literal zero through a generic function loses its null-pointer-constant
  meaning. This is a diagnostic harness defect, not a new package defect. The
  revised candidate materializes only floating comparisons, retaining original
  pointer/string/integer comparison expressions. Its focused probe checks
  exact values, null literals, distinct uint64/float values, mixed float/double
  values and NaN without any tolerance. Full rechecks now compile: x86_64
  passes all three CTest entries, while i686 is reduced from 114 failing cases/
  686 assertions to 14 cases/28 assertions (658 assertions eliminated). These
  include the two separately diagnosed archive failures, formatted-output
  differences and numerical discrepancies; none is silently excluded.
  Details: `failures/opencolorio-scalar-typed-equality-v2.json`.
  Remaining numerical differences are not dismissed as harmless. Independent
  numerical review (`parallel/ocio-numerical-review/review.md`) identifies
  concrete fixture-width issues separately from stored rendering differences.
  The public shared-library ACES2 probe reproduces the same cyan failure under
  generic i686: identical input bits yield red 0.00970779825, exceeding the
  unchanged 0.007000000216 tolerance. Scalar x86_64 and the SSE2-library control
  both return about 7.3094e-7 and pass. Matching loaders and library versions are
  recorded; this is not merely test-source inlining or a comparator artifact.
  First prefix divergence is already visible in display-inverse XYZ. A
  `-ffloat-store` generic-x87 diagnostic now completes: the public cyan case
  improves to red 0.00622071372 and passes the original threshold, but the full
  suite still fails 11 cases/25 assertions in that diagnostic, including the
  then-unfixed minizip archive cases (only core filesystem calls were wide).
  The flag is not adopted: it neither establishes whole-package correctness
  nor resolves the other arithmetic/fixture issues. Reference-accuracy checks
  remain necessary. Evidence: `opencolorio-aces2-public-*.{json,log}` and
  `parallel/ocio-numerical-review/aces2-*-loader.txt`.
  A further compiler control uses Clang with SIMD OFF and explicit
  `-march=i686 -mno-sse -mno-sse2 -mfpmath=387`, retaining original tests and
  tolerances. It compiles and reaches all 1141 CPU cases, but fails 22 cases/
  21011 assertions; Python CTest passes. 20895 assertions are concentrated in
  CPUProcessor/optimizations, so this is not a count of distinct rendering bugs.
  Saved alpha examples are integers 32770 versus 32771: do not dismiss them as
  harmless floating-comparator noise. ACES2 round-trip still fails two SDRwhite
  assertions (REC709/P3 SDR100, expected white versus actual black), not HDRcyan.
  No compiler switch is adopted.
  Evidence: `opencolorio-i686-clang-x87-checks.json`,
  `failures/opencolorio-clang-x87-summary.json` and the diagnostic recipe.
  The failed build is retained. Its public HDR4000 probe passes all four sampled
  colors, with cyan red 0.00622071372 (same as GCC float-store), preserving the
  original tolerance. This does not erase the full-suite SDRwhite failures.
  `opencolorio-aces2-public-i686-clang-x87.{json,log}` records this result.
  Bounded source analysis identifies a plausible NaN-to-zero clamp but no proven
  local repair (`parallel/ocio-numerical-review/x87-source-analysis.md`).
  Uninstrumented public SDRwhite probes now reproduce Clang's REC709/P3 blackout
  with original tolerances. GCC, float-store, scalar64 and SSE2 controls pass both
  profiles. Clang view-inverse output is finite near RGB128, but view-forward
  returns zero. This is an actual public-library regression in the compiler
  experiment, not only an assertion artifact. See
  `parallel/ocio-numerical-review/sdr-white-comparison.json` and
  `opencolorio-sdr-white-*.{json,log}`. Public operation-boundary/cross-fed-input
  measurements are next; no arithmetic change or NaN-cause claim yet.
  SSE2 plus the core large-file fix eliminates those numerical assertion failures,
  but still fails two archive processor-cache equality cases in each enabled
  CPU dispatch run. All 398 Python tests pass. A fresh public-API archive probe
  exposes a further real defect: the generated ZIP contains only `config.ocio`,
  omitting its LUT files. Direct calls to the linked minizip-ng library confirm
  directory reading returns NULL/EOVERFLOW and directory classification fails
  on this filesystem. Its binary still imports narrow `readdir` and `stat`.
  A matching wide-file minizip/OCIO comparison now passes: minizip's 168 tests,
  all 10 OpenColorIO CTest entries, and an external directory/archiving consumer.
  The directory probe finds 11 entries with no errno; the archive contains 10
  members rather than just the config. An assertion-backed public Python probe
  confirms context-free config cache equality, processor cache equality, exact
  transform data and serialized config equality. Contextual config cache IDs
  legitimately differ with filesystem/proxy context and are not conflated with
  the context-free assertion. This remains diagnostic: `mz_os_read_dir` exposes
  `struct dirent`, so adopting wide-file compilation needs explicit consumer/
  public-ABI review, not a silent flag flip. SSE2 is still not adopted as the
  generic i686 baseline; the scalar/x87 investigation remains separate.
  Independent review blocks promotion of the private-flag diagnostic unchanged:
  publish the ABI requirement through both CMake target definitions and pkg-config
  Cflags, and coordinate consumer rebuilding. OCIO's config-package path carries
  definitions, but its pkg-config fallback currently drops compiler flags.
  Review: `parallel/minizip-abi-review/review.md`. A private same-SONAME wide
  variant is not an adequate isolation mechanism. A public-contract candidate
  is now applied locally: an explicit upstream-style option exports the same
  definition to library compilation, CMake consumers and pkg-config Cflags;
  Nix enables it only for 32-bit GNU/Linux. The OCIO finder forwards fallback
  compilation flags and selects the installed config path. Fresh normal/compat
  builds now pass 168 tests each. The first metadata consumer compile correctly
  receives the public flag, but its runtime gate rejects the freshly created
  home-subvolume fixture because its inode is below UINT32_MAX. This is a
  fixture/precondition failure, not a package failure. Consumers are being rerun
  read-only against retained directory inode 4303727531, file 4303727532 and
  subdirectory 4303727537; original fixture/log evidence is preserved.
  Six normal-package C/C++ consumers now pass on those high inodes through
  CMake, pkg-config and raw compiler usage. The compatibility CMake probe then
  exposed a harness search-path omission: dependency prefixes contained dev
  outputs but not the matching target libraries. Prefixes are corrected without
  package changes. The full matrix now passes: 16 C/C++ consumers across
  normal/compat CMake, pkg-config, raw compiler use and both OCIO finder paths;
  none receives a manual LFS flag. All confirm pointer=32, off_t=8, ino_t=8,
  time_t=4 and d_name offset=19. Negative controls specifically reject old
  private-wide metadata and the original flag-dropping finder. Evidence:
  `parallel/minizip-public-validation/passed.json`. Actual OCIO project builds
  now pass all 10 CTest entries through BOTH config-package and forced
  pkg-config discovery. Compile-command assertions prove Platform.cpp,
  OCIOZArchive.cpp and ocioarchive receive metadata-derived FILE_OFFSET_BITS=64
  with no ambient/private file/time flags. These remain SSE2 comparison builds,
  not generic-x87 correctness claims. Legacy FILE32 mode configuration is
  accepted when wide mode is OFF; requesting both modes is specifically
  rejected. Platform-predicate checks pass (ARM is evaluation-only, not runtime).
  Evidence: `opencolorio-i686-public-lfs-{config,pkgconfig}-result/nix-support/`
  and `parallel/minizip-public-validation/option-guards/passed.json`.
  Actual consumer runtime/closure coverage remains limited. Both x86_64 minizip
  derivations are verified unchanged (`audit/minizip-{before,after}-public-contract.json`).
  Independent final review found no concrete defect. Committed and pushed:
  integration `1bfa643c7119`, focused `33c29fc6802c` (one commit on BASE).
  This is an intentional coordinated 32-bit ABI transition; old narrow binaries
  remain incompatible, and closure-wide consumer safety is not certified.
  Review: `parallel/minizip-public-validation/final-review.md`; draft:
  `prs/minizip-ng/pr.md`. Independent focused-branch evaluation/build on BASE
  resolves both normal/compat variants to the exact previously tested outputs
  (`parallel/minizip-public-validation/focused-branch-passed.json`); this reused
  cached artifacts rather than rerunning the 168 tests.
  The separate OCIO finder repair now passes production
  x86_64 build/all 10 CTest entries and is committed/pushed: integration
  `883f6d3b3af9`, focused `2939057da7a3`. Evidence:
  `opencolorio-x86_64-public-metadata.{json,log}`. The focused finder branch
  also independently builds on otherwise unmodified BASE for x86_64 and passes
  all 10 CTest entries, producing a distinct artifact (not integration cache
  reuse): `opencolorio-focused-x86_64-build.{json,log}` and
  `parallel/minizip-public-validation/ocio-focused-x64-passed.json`.
  No generic-x87 accuracy claim;
  no production CPU, math or test-selection change.
  Pinned consumer inspection confirms Millennium uses the imported-target path
  (not the initially suspected raw bypass), and Telegram's packaged helper
  forwards compatibility CMake/pkg-config requirements. Remaining exact-source
  gaps were inspected after exact pinned fetches. Linphone Qt-only
  desktop does not consume the stale raw MINIZIP variables; DJV uses tlRender
  targets; tlCore's inspected public FileInfo uses fixed-width sizes and
  unchanged time_t, not a cross-library dirent/stat/off_t object. No additional
  consumer repair was proven. Exact feather-tk FileIO headers now show a
  pointer/size_t InMemoryFile and a pimpl FileIO interface, not public libc
  offset/directory layouts (`parallel/minizip-consumer-source-audit/feather-fileio.md`).
  Dolphin's pinned helper uses a pkg-config imported target and INTERFACE alias
  (`parallel/minizip-consumer-source-audit/dolphin-discovery.md`); no flag-dropping
  reconstruction was found there. Two helper C/C++ runtime probes passed, but
  initial evidence collection failed because compile-command export was enabled
  after targets were created. This is a preserved harness failure, not a package
  failure. A fresh-directory retry enables export before target creation and
  now passes both runtime probes and compile-command flag assertions:
  `parallel/minizip-public-validation/dolphin-discovery-passed.json`. This adds
  two actual-helper probes beyond the 16-consumer matrix, not a Dolphin app build. Actual consumer compile/runtime closure
  coverage remains limited; an explicitly SSE2-labelled tlRender/Krita
  comparison is running, without changing package
  defaults or force-enabling unsupported platforms. Audits:
  `parallel/minizip-consumer-source-audit/{audit,audit-exact-sources}.md`.
  Evidence: `audit/minizip-directory-probe.{c,txt}` and
  `audit/opencolorio-archive-sse2-probe2/` (failed round-trip retained),
  `audit/opencolorio-archive-matched-lfs-probe2/` (assertion-backed success), and
  `{minizip,opencolorio}-i686-*matched-lfs*.{json,log}`.
  Evidence: `opencolorio-i686-scalar-lfs{,-standard}-checks.{json,log}` and
  `audit/opencolorio-equality-probe*`.

Source/reproducer evidence is in `parallel/{qmake,yaml}-diagnosis/`; root builder
logs are under `failures/`. yaml-cpp and gavl are now validated and committed;
Qt5/Qt6 tool repairs and PyQt6 are also validated, committed and pushed.
The full downstream Krita build remains blocked by OpenColorIO; its dependency
experiments are not counted as completed package repairs.

No PRs opened automatically. Drafts disclose AI assistance and require operator
review. Avoid disabling whole test suites or bypassing unsupported-platform
checks to force a build.
