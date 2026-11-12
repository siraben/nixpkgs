# minizip-ng / OpenColorIO large-inode ABI review

## Review

- **Correct:** The matched-wide experiment addresses both filesystem seams, not just OCIO’s `stat`. OCIO reads `entry->d_name` across the minizip library boundary; therefore matching compilation modes matter.
- **Fixed:** None. Read-only review; no commands, builds, tests, or repository changes performed.
- **Finding: P1 — The diagnostic wide minizip lacks a public compilation contract.** Promoting it unchanged would permit incompatible consumers.
- **Finding: P1 — OCIO’s pkg-config fallback drops compilation flags.** Exporting the definition in `.pc` alone will not repair that discovery path.
- **Merge verdict: BLOCK** promotion of the diagnostic recipe unchanged. A coordinated package-wide LFS change is feasible, subject to the propagation and consumer checks below. This is not a verdict on unrelated integration edits.

### Scope and evidence notation

`R` = `/home/siraben/i686-iso-work/refresh-20261111`

`M` = `/nix/store/vqpdqq029p6rhjxxn7xglbw5lmzxzx9q-source`

`O` = `/nix/store/2ywir6xhl7nlyyayqvgh7f1bxw9pkg59-source`

This reviews current source, package expressions, installed diagnostic metadata, and retained evidence—not a committed diff. No minizip/OCIO production change was supplied. SSE2 policy is excluded.

## 1. Public ABI: private `_FILE_OFFSET_BITS=64` is insufficient

**Yes: compiling only minizip wide can break a narrow consumer reading `struct dirent`.**

Evidence:

- `M/mz_os.h:49–57` includes the system directory-entry definition.
- `M/mz_os.h:166–168` publicly returns `struct dirent *`.
- `M/mz_os_posix.c:288–291` returns `readdir(dir)` directly; there is no library-owned representation or conversion.
- `O/src/OpenColorIO/OCIOZArchive.cpp:154–175` dereferences the returned entry’s `d_name`.
- On 32-bit glibc, file-offset mode changes this system structure’s layout. An unchanged pointer-returning symbol does not encode that distinction.

The diagnostic recipe applies the flag separately to both packages (`R/opencolorio-minizip-lfs-comparison.nix:8–17`), so its success does **not** establish safe propagation to ordinary consumers.

Its installed metadata confirms the gap:

- `R/minizip-i686-matched-lfs-result/lib/cmake/minizip-ng/minizip-ng-targets.cmake:55–57` exports include directories but no `INTERFACE_COMPILE_DEFINITIONS`.
- `…/lib/pkgconfig/minizip-ng.pc:14` supplies only an include flag.

**Smallest correction:** make `_FILE_OFFSET_BITS=64` a public build requirement whenever this package is compiled in that mode, and rebuild consumers against that contract. A private compiler flag alone is not a production fix.

Do **not** add `_TIME_BITS=64` as part of this repair. The API also exposes `time_t` arguments and pointers (`M/mz_os.h:145–148`) and embeds `time_t` in `mz_zip_file` (`M/mz_zip.h:25–33`). Changing time width would introduce another ABI transition unrelated to the inode fix.

## 2. Required metadata and OCIO propagation

### minizip CMake and pkg-config

Use one conditional public-definition list consistently:

- Apply `target_compile_definitions(${MINIZIP_TARGET} PUBLIC _FILE_OFFSET_BITS=64)` when enabling this mode.
- Add `-D_FILE_OFFSET_BITS=64` to the generated `.pc` file’s **`Cflags`**, not private dependency/link fields.

Apply the property to the real target, `${MINIZIP_TARGET}`:

| Build | Installed imported target | pkg-config module |
|---|---|---|
| Normal Nixpkgs package | `MINIZIP::minizip-ng` | `minizip-ng` |
| Compatibility package | `MINIZIP::minizip` | `minizip` |

Target naming and export are established by `M/CMakeLists.txt:90–95,702–710,759–767`. The build-tree `MINIZIP::minizip` alias is not an additional installed normal-package target.

Currently all collected definitions are private (`M/CMakeLists.txt:733`), and `M/minizip.pc.cmakein:14` has no definition placeholder. Do not make the entire existing private-definition list public: feature implementation flags and libc-internal `__USE_*` macros are not the proposed contract.

### OCIO’s config-package path: propagates definitions

`O/share/cmake/modules/Findminizip-ng.cmake:48–59` first loads the installed config package. It replaces `INTERFACE_LINK_LIBRARIES`, but does **not** remove `INTERFACE_COMPILE_DEFINITIONS`.

OCIO links that target into:

- `OpenColorIO`, at `O/src/OpenColorIO/CMakeLists.txt:318–329`;
- `ocioarchive`, at `O/src/apps/ocioarchive/CMakeLists.txt:21–24`.

Consequently, a public definition on the imported target reaches the compilation of both `Platform.cpp` and `OCIOZArchive.cpp`. OCIO need not duplicate the flag privately when this path is verified.

### OCIO’s pkg-config fallback: does not propagate definitions

The finder calls `pkg_check_modules` without `IMPORTED_TARGET` (`…/Findminizip-ng.cmake:111–113`). Its replacement imported target receives only location/include properties and a zlib link (`:195–205`); it never consumes `PC_minizip-ng_CFLAGS_OTHER`.

**Smallest upstream correction:** apply those flags using `target_compile_options(... INTERFACE ${PC_minizip-ng_CFLAGS_OTHER})` when constructing the fallback target, or reuse a pkg-config imported target.

For the minimal Nixpkgs production path, explicitly selecting the installed config directory is sufficient to avoid depending on this fallback. The existing include-directory override in `pkgs/by-name/op/opencolorio/package.nix:85` does not itself export an ABI definition.

## 3. Recommended production change

**Prefer one coherently rebuilt minizip package, not an OCIO-private wide shared variant.**

1. Add a small upstream-style minizip build-system patch implementing the public definition and `.pc` flag together.
2. Enable that mode in the package for:
   `stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isGnu && stdenv.hostPlatform.is32bit`.
   This scopes the GNU/Linux repair without treating all Unix platforms identically. It must use the **host**, not build, platform.
3. Preserve `MZ_FILE32_API` semantics: do not silently force wide mode when a caller explicitly requests the 32-bit file API. Nixpkgs currently leaves that option off.
4. Ensure OCIO selects `minizip-ng`’s config package; verify its actual compilation receives the definition transitively.
5. Rebuild/audit the affected consumers below. Keep the existing i686 `MZ_PKCRYPT=false`, test selection, and CPU-policy decisions unchanged.

For an upstream patch, establish applicability with target-platform/libc compile checks rather than detecting the machine running CMake.

**ABI qualification:** public metadata coordinates newly compiled consumers; it does not make old narrow binaries ABI-compatible. Describe this as a coordinated 32-bit package ABI transition, not an ABI-neutral compiler cleanup. Manual header/library users also need the documented flag.

If maintaining compatibility with unrecompiled consumers is mandatory, this small transition is insufficient. The upstream alternative is a new directory API with a library-owned representation or explicit dual ABI, preserving the old entry point. That requires additional source design and testing.

### Private-variant/co-loading risk

The diagnostic wide build retains `libminizip-ng.so.4` (`R/minizip-i686-matched-lfs-result/lib/cmake/minizip-ng/minizip-ng-targets-release.cmake:12`).

A different Nix store path does not provide an ELF symbol namespace. Narrow and wide same-SONAME variants can be substituted or interposed within one process. This is particularly relevant because both tlrender and DJV depend on minizip **and** OCIO.

A private wide override is therefore not an adequate isolation mechanism. A different SONAME alone also does not eliminate symbol interposition if both implementations are loaded. Avoid parallel incompatible variants; otherwise genuine symbol isolation/versioning is required.

## 4. Bounded Nixpkgs consumer audit

An exhaustive textual search for `minizip-ng|minizip_ng` in Nix expressions found these relevant references; no package evaluation or builds were performed.

| Consumer | Verified expression evidence | Review consequence |
|---|---|---|
| OCIO | `pkgs/by-name/op/opencolorio/package.nix:61,85` | Direct cross-library `dirent` exposure confirmed above. |
| tlrender | `pkgs/by-name/tl/tlrender/package.nix:97,109`; `minizip-ng-4.patch:35–57` | Patch explicitly links imported minizip targets; config definitions should propagate. Also co-loads OCIO when enabled. |
| DJV | `pkgs/by-name/dj/djv/package.nix:56–63` | Depends on tlrender, minizip and OCIO; important coherent-closure check. |
| dolphin-emu | `pkgs/by-name/do/dolphin-emu/package.nix:83–85,111` | CMake/pkg-config available; expression alone does not establish which discovery path consumes flags. |
| swayimg | `pkgs/by-name/sw/swayimg/package.nix:54–57,85` | Meson/pkg-config consumer candidate; verify actual dependency flags. |
| linphone-desktop | `pkgs/applications/networking/instant-messengers/linphone/linphone-desktop/default.nix:111–112,137–142` | Supplies raw include/library variables and removes custom find modules. Do not assume metadata propagation. |
| millennium | `pkgs/by-name/mi/millennium/package.nix:122–134,182` | Explicit i686 minizip dependency; cannot omit from the 32-bit audit. |
| telegram-desktop | `pkgs/applications/networking/instant-messengers/telegram/telegram-desktop/unwrapped.nix:63–67,84` | Uses the compatibility variant; audit separately. |

`minizip-ng-compat/package.nix:4–5` simply overrides the shared expression, so a package-level change affects it too. BRL-CAD’s occurrence is a removed vendored subproject; VPKEdit’s occurrence documents its vendored dependency, not a dependency on this package.

Except for the cited OCIO source and tlrender patch, these expressions do **not** prove which public structures consumers access. That remains a source/compile-command verification requirement, not an established additional defect.

## 5. Parent validation gates

Existing evidence supports the mechanism:

- Narrow probe: `R/audit/minizip-directory-probe.txt:1` records errno 75 and directory status `-107`.
- Matched-wide probe: `R/minizip-i686-matched-lfs-directory.log:1` records successful enumeration and `d_name_offset=19`.
- Retained minizip log reports 168 passing tests (`R/minizip-i686-matched-lfs-checks.log:474`).
- Retained OCIO comparison reports ten passing CTest entries (`R/opencolorio-i686-sse2-matched-lfs-checks.log:669`).
- The assertion-backed archive probe verifies LUT membership and round-trip consistency; retained results contain ten archive members.

Before accepting production changes, the parent should run:

1. Fresh installed-package C and C++ probes consuming **only** CMake target requirements, then only pkg-config flags—no manually injected LFS flag.
2. OCIO config-package and forced pkg-config-fallback discovery checks; inspect actual compiler commands.
3. High-inode directory enumeration and archive round-trip assertions, including nested LUT files.
4. minizip’s 168 tests, both package variants’ metadata checks, and OCIO’s relevant suites.
5. Targeted consumer checks above, prioritizing linphone, millennium, tlrender/DJV, and Telegram.
6. An x86_64 regression check and a guard check confirming unrelated platforms are unchanged.

The existing SSE2 comparison results establish neither generic-i686 CPU compatibility nor completion of the separate scalar arithmetic investigation.