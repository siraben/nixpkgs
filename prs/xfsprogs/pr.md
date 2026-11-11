## xfsprogs: fix transaction delta type on 32-bit

### Description of changes

Backport upstream commit
[1c042af146e6](https://git.kernel.org/pub/scm/fs/xfs/xfsprogs-dev.git/commit/?id=1c042af146e6b94e43a16f6645e05b6c2ab4b299),
`libxfs: remove stale xfs_trans_mod_sb() declaration`.

xfsprogs 7.2.1 uses the kernel's xfs_trans.h, which declares the transaction
delta as int64_t. A stale declaration and the userspace definition still use
long, causing conflicting types on i686. The upstream patch removes the stale
declaration and changes the definition to int64_t. Fetch the pinned upstream
patch directly from kernel.org, preserving attribution. An initial vendored
copy was replaced during the style audit; both fetched-patch builds pass.

### Validation

- Reproduced the conflicting-type compiler failure on unpatched i686.
- Patched builds succeed on i686-linux and x86_64-linux.
- `mkfs.xfs -V` runs successfully from both outputs.
- Formatting and whitespace checks pass.
- Xfce ISO builds; live and installed desktop boot verified with the integration
  stack. The dedicated xfsprogs installer passthru test was not run.

```sh
nix-build . -A xfsprogs --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A xfsprogs --argstr system x86_64-linux
```

Prepared with AI assistance; operator review required before submission.
