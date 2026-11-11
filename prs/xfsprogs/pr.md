## xfsprogs: fix transaction delta type on 32-bit

### Description of changes

Backport upstream commit
[1c042af146e6](https://git.kernel.org/pub/scm/fs/xfs/xfsprogs-dev.git/commit/?id=1c042af146e6b94e43a16f6645e05b6c2ab4b299),
`libxfs: remove stale xfs_trans_mod_sb() declaration`.

xfsprogs 7.2.1 uses the kernel's xfs_trans.h, which declares the transaction
delta as int64_t. A stale declaration and the userspace definition still use
long, causing conflicting types on i686. The upstream patch removes the stale
declaration and changes the definition to int64_t. Patch content was retrieved
from Gentoo's xfsprogs packaging and is vendored with its upstream attribution.

### Validation

- Reproduced the conflicting-type compiler failure on unpatched i686.
- Patched builds succeed on i686-linux and x86_64-linux.
- `mkfs.xfs -V` runs successfully from both outputs.
- Nix expression whitespace checks pass; the patch retains significant
  space/tab-prefixed unified-diff context.
- NixOS installer passthru test and full ISO validation not yet run.

```sh
nix-build . -A xfsprogs --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A xfsprogs --argstr system x86_64-linux
```

Prepared with AI assistance; operator review required before submission.
