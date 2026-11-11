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
  Result link: `xfce-result`. Fresh live and installed boot tests are pending;
  the older ISO's boot evidence does not cover this artifact.
- PR drafts are under `prs/<package>/pr.md`. Publish them on a separate docs
  branch so source PR diffs remain focused. No PRs have been opened.
- SSH access to fork confirmed after operator authenticated.
- Existing upstream PR #558908 already covers TCP_AO on 32-bit; do not create
  a duplicate PR if this remains a blocker.
