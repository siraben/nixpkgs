# Xfce i686 refresh — 2026-11-11

## Request
Rebuild the Xfce i686 ISO against current upstream; investigate 32-bit failures,
prepare focused fix branches and `pr.md` drafts, and push validated branches to
siraben/nixpkgs. Do not open PRs automatically.

## Initial observations
- Existing worktree `/home/siraben/nixpkgs-32bit` is clean at
  `37e69cbac0c676a3bd3ce1bfbcd9305cd3bb142c` and will be preserved.
- Use a separate integration worktree and pinned upstream revision for this run.
- Earlier ARM32 fixes merged: marshmallow #575094 and alsa-firmware #575089.
- Host extra-platforms omits i686; explicitly pass i686-linux for builds.
- Keep durable logs and inspect long builds at 10-minute intervals.
- Previous successful ISO and QEMU evidence remains under the parent directory;
  it does not establish correctness of this new build.

## State
- Pinned upstream: `a238bac4849a79e151329cdc51638d3bc7627c6c`.
- Interrupted checkout repaired; baseline working tree verified clean.
- Baseline evaluation fails on 64-bit-only QEMU guest tools. Guarding that
  exposes broken Firefox on i686; adding Dillo fallback makes evaluation pass.
  Evidence: `baseline-eval.log`, `eval-qemu-guard.log`, `eval-browser-fallback.out`.
- First build interrupted by session/process termination without a package
  failure. Preserve `xfce-attempt1.log`. A temporary user service was stopped
  at the operator's request; all subsequent builds use bg_run directly.
- Complete census `xfce-attempt3` exposed 11 root builder failures. All 11 now
  have separately committed and package-validated fixes; see `FAILURES.md`.
- Ten focused new package branches prepared on pinned BASE, with per-package
  i686/x86_64 build evidence. Package builds were tested in the integration
  stack, not with all other fixes reverted; standalone branch dependencies
  may require the other PRs to merge first. Rapidjson uses existing PR #534793, carried with
  original author credit rather than submitted as a duplicate.
- Integration branch: `siraben/i686-xfce-refresh-20261111`.
- `xfce-attempt4` got past the original failures, then failed in kernel config
  and Dask. Existing TCP_AO PR #558908 passes config generation and is carried
  with author credit. Linux 6.18.63 subsequently built successfully.
- Dask exposed a separate pandas nullable Arrow-string join runtime bug. It
  was independently reproduced, fixed, tested on i686/x86_64, committed and
  pushed as `siraben/i686-pandas-20261111`.
- Dask portable test changes now pass the full suite on both architectures;
  a separate Dask branch/draft is prepared. Its tests require the pandas fix.
- `xfce-attempt5` exposed afdko and external ZFS module failures. Afdko's
  exact-output overlap test is excluded on i686 (two coordinates differ by
  0.01); all remaining tests pass. Kernel dev pruning now retains Makefile
  fragments, enabling ZFS builds on i686 and x86_64. Both fixes are pushed.
- `xfce-attempt6` reached initrd assembly but requested unavailable Hyper-V
  modules. Supported-architecture guards fix that; x86_64 kernel/initrd and
  Hyper-V service derivations are unchanged.
- `xfce-attempt7` SUCCESS: the complete 2.4 GiB Xfce i686 ISO built at
  `/nix/store/8a9z6yyv0256qagdl3xcgclhmbmnvswh-nixos-xfce-26.11pre-git-i686-linux.iso`.
  Result link: `xfce-result`. Fresh live Xfce boot passed. Offline installation
  completed (success marker just after harness timeout), followed by a passing
  disk-only installed Xfce boot. Evidence: `test-xfce-live/live-passed.json`,
  `test-xfce-install/installed-passed.json` and serial logs.
- Expanded survey: MATE, GIMP and Inkscape build without new fixes. LXQt now
  builds after PySide6 optional-web availability, Shiboken extent-type and
  Qt Multimedia scalar-fallback fixes; all three packages build on both widths.
  Fresh MATE and LXQt live ISO BIOS/QEMU graphical boot checks now pass,
  including panels, file managers, terminals and stability. PySide6 offscreen
  widget rendering passes on both widths.
- liborcus rounding test fix passes all 59 tests on both widths. LibreOffice
  remains under repair: native-i686 Java default, bundled Box2D SIMD selection,
  skcms musttail ABI, then repeated undefined inherited refcount thunks in file
  picker/XML import. Reject class-by-class overrides; testing an i686/GCC16-only
  compiler devirtualization workaround instead.
- Per-fix style review in `audit/style-review.md`. Three style fixups have been
  autosquashed, preserving author credit and backup refs. Changed focused
  branches and integration are pushed/verified with exact old-hash leases.
  All 30 currently changed Nix files pass formatting, including pending
  candidates; formatting is not correctness evidence. See `report.md`.
- Krita survey uncovered qmake large-inode failures, gavl time ABI mismatch and
  yaml-cpp serialization truncation. yaml-cpp and gavl repairs pass both-width
  validation, are separately committed and pushed, with drafts. Qt5's private
  qmake large-file repair also passes both full builds and installed-tool
  checks, and is committed. Qt6's private qmake repair also passes both builds
  and an exact installed-tool high-inode regression, and is committed.
  PyQt6 now builds/imports and renders offscreen text on both widths, with
  optional PDF modules absent/present as expected. Focused PyQt6 branch
  9c2686c4f13c and integration d6ff01421387 are pushed/verified. Full Krita
  remains blocked by OpenColorIO.
- RawTherapee builds and converts a 16-bit TIFF to a verified 64x64 JPEG on
  i686. No new RawTherapee fix needed. digiKam's unconditional upstream
  QtWebEngine dependency is a recorded porting limitation, not bypassed.
- New pending investigations: LibreOffice's real duplicate-font-mapping repair
  passes all 87 Writer tests; supported AFDKO driver recompilation passes the
  PDF-font regression and three embedding tests. Other i686 failures remain;
  full x86_64 regression is running. No successful LibreOffice i686 package claim.
- Minizip public wide-file contract: both variants pass 168 tests; all 16
  metadata-only high-inode consumers and two negative controls pass. Legacy and
  conflicting-mode guards pass. Actual OCIO config/pkg-config discovery builds
  each pass 10 CTests with metadata-derived compile flags (SSE2 diagnostic,
  not generic-x87 sign-off). Source audits and independent final review found
  no additional concrete defect. Minizip committed/pushed: integration
  1bfa643c7119, focused 33c29fc6802c. Coordinated consumer rebuild required;
  old narrow binaries incompatible. Broad application/closure coverage remains
  limited. Separate OCIO finder repair also passes all 10 production x86_64
  CTests and is committed/pushed: integration 883f6d3b3af9, focused 2939057da7a3.
  No generic-x87 accuracy claim or production CPU/math/check-selection change.
- OpenColorIO generic x87 has a reproduced public-API ACES2 accuracy failure;
  `-ffloat-store` improves that one case but leaves 25 assertions failing.
  No SSE2 CPU-baseline change, test-tolerance inflation or global workaround
  adopted. See `report.md` for diagnostic evidence and limitations.
- PR drafts are under `prs/<package>/pr.md`. Publish them on a separate docs
  branch so source PR diffs remain focused. No PRs have been opened.
- SSH access to fork confirmed after operator authenticated.
- Existing upstream PR #558908 already covers TCP_AO on 32-bit; do not create
  a duplicate PR if this remains a blocker.
