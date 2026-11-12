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
| Qt5 qtbase/qmake | Enable private bootstrap large-file ABI, avoiding inode-overflow enumeration failures | Full builds on both widths; readdir64/stat64 imports and project discovery checked | qt5-qmake |
| yaml-cpp | Backport upstream uint64_t Dragonbox significand fix, preventing wrong serialized magnitudes | Full builds/CTest pass on both widths; 15-case i686 runtime reproducer passes | yaml-cpp |
| gavl | Select 64-bit glibc time ABI on 32-bit, matching int64_t HTTP timestamps | Both builds; 1969/1970/2040 HTTP date round trips pass on each width | gavl |
| PySide6 | Omit optional unavailable WebEngine/WebView modules using availableOn | Both builds and offscreen widget renders; full i686 LXQt system builds | pyside6 |
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
| LibreOffice 26.8.0.3 | Production compiles/links; portable fixture fixes pass, but standard excess precision does not resolve remaining numerical/runtime failures; font-export test times out | Run x86_64 comparison concurrently and an explicitly SSE2-only diagnostic variant; generic i686 baseline not raised |
| Krita 6.0.4.1 | PDF selection fixed in evaluation; full attempt found PyQt6/qmake large-inode handling, Qt5 bootstrap enumeration, gavl timestamp ABI and yaml-cpp runtime serialization blockers | Validate each focused repair, then rebuild Krita |
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

- All 28 changed Nix files, including pending dependency repairs and LibreOffice, pass `nixfmt --check`
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
claim or commit has been made. The independent x86_64 comparison is pending.
The crash reproduces on a copied dataset: GDB shows SIGABRT during SAL's
UTF-8 file-URL-to-system-path conversion, reached from HelpIndexer file reading;
this is memory corruption, not a numeric assertion (`libreoffice-help-indexer-backtrace.log`).

A separate Clang diagnostic explicitly sets `-march=i686`: the compiler's
normal i686-target default is Pentium 4, so merely switching compilers would
silently introduce SSE2. Preprocessor/driver checks confirm the explicit
variant defines i386/i686 but no SSE macros. This diagnostic is not committed
as the generic package implementation. The prior Xfce artifact is validated as built, not claimed byte-for-
byte identical to an ISO embedding the subsequently amended Nixpkgs source.

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
  commit: 2941d121d546. Qt6 full validation is pending. Upstream Gerrit duplicate checking was
  blocked by HTTP 403; do not claim a comprehensive upstream search.
- **gavl:** HTTP API uses int64_t but gmtime_r expects native time_t. Select
  glibc's 64-bit time ABI on 32-bit. Both builds and HTTP dates before 1970
  and after 2038 pass; individually committed as 8f47126e691a. Public headers
  expose no libc time/stat structs; the HTTP API retains int64_t.
- **PyQt6:** optional PDF default now follows QtWebEngine availability; x86_64
  build passes, i686 reached installation and hit the qmake inode bug above.

Source/reproducer evidence is in `parallel/{qmake,yaml}-diagnosis/`; root builder
logs are under `failures/`. yaml-cpp and gavl are now validated and committed;
Qt5's tool repair is also validated and committed; Qt6 and PyQt6 remain pending full validation. They are not
counted as fixed until their required checks and individual commits succeed.

No PRs opened automatically. Drafts disclose AI assistance and require operator
review. Avoid disabling whole test suites or bypassing unsupported-platform
checks to force a build.
