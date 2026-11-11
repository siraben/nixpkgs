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
  with author credit. Full kernel build is still pending.
- Dask exposed a separate pandas nullable Arrow-string join runtime bug. It
  was independently reproduced, fixed, tested on i686/x86_64, committed and
  pushed as `siraben/i686-pandas-20261111`.
- Dask portable test changes now pass the full suite on both architectures;
  a separate Dask branch/draft is prepared. Its tests require the pandas fix.
- `xfce-attempt5` is next. Further downstream failures may emerge; no new ISO
  success or boot success is claimed yet.
- PR drafts are under `prs/<package>/pr.md`. Publish them on a separate docs
  branch so source PR diffs remain focused. No PRs have been opened.
- SSH access to fork confirmed after operator authenticated.
- Existing upstream PR #558908 already covers TCP_AO on 32-bit; do not create
  a duplicate PR if this remains a blocker.
