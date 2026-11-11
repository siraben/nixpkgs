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
| PySide6 | Omit optional unavailable WebEngine/WebView modules using availableOn | Both builds and offscreen widget renders; full i686 LXQt system builds | pyside6 |
| Graphical installer | Avoid unavailable QEMU guest agent/Firefox on 32-bit, use Dillo | Full ISO and live Xfce boot | graphical-base |
| Hyper-V installer/hardware profiles | Do not require unavailable Hyper-V modules on i686 | Full ISO; x86_64 kernel/initrd/service derivations unchanged | hyperv |

Earlier alsa-firmware (#575089) and marshmallow (#575094) fixes were merged
upstream before this pinned base; they are historical work, not new fixes in
this stack. ARM validation was not established for those changes.

## Expanded substantial-software survey

| Target | Observed result | Next action |
|---|---|---|
| MATE desktop NixOS system | Build passed | No new fix needed; graphical runtime not yet tested |
| GIMP 3.2.6 | Build passed | No new fix needed; no interactive runtime claim |
| Inkscape 1.4.4 | Build passed | No new fix needed; no interactive runtime claim |
| LXQt desktop NixOS system | **Full build passed**, including the three new dependency fixes | Graphical runtime not yet tested |
| LibreOffice 26.8.0.3 | Non-Java evaluation and liborcus/Box2D/skcms blockers passed; repeated GCC 16 inherited-refcount thunk link failures | Reject class-by-class patch; validate i686/GCC16-only devirtualization workaround; Java remains unavailable |

Logs: `survey-*-i686.{json,log}` and `trace-{lxqt,libreoffice}-i686.log`.
The survey does not establish that every supported 32-bit application works.
OpenJDK's bootstrap limitation is already tracked in #314873 and open PR
#575087 (metadata restriction, not a working bootstrap). No duplicate PR made.

## Style and idiom audit (ongoing)

- All 23 changed Nix files, including pending LibreOffice, pass `nixfmt --check`
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
style pass. The prior Xfce artifact is validated as built, not claimed byte-for-
byte identical to an ISO embedding the subsequently amended Nixpkgs source.

No PRs opened automatically. Drafts disclose AI assistance and require operator
review. Avoid disabling whole test suites or bypassing unsupported-platform
checks to force a build.
