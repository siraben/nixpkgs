## rsync: match large-file ABI in 32-bit security test hook

### Description of changes

On 32-bit Linux, rsync uses the large-file ABI, but the LD_PRELOAD hook in
`partial-protected-regular-retry-linux_test.py` intercepts the non-LFS symbols.
The positive control then fails because rsync bypasses the injected race hook.

Compile the hook with `_FILE_OFFSET_BITS=64` and resolve the matching
`open64`, `openat64`, `fstatat64`, and `__fxstatat64` functions through
`RTLD_NEXT`. This repairs the regression test rather than skipping it; the
installed rsync code is unchanged.

### Validation

- Baseline i686 build reproduced `FAIL partial-protected-regular-retry-linux`.
- Patched i686 build succeeds, explicitly reporting
  `PASS partial-protected-regular-retry-linux` with the normal test suite enabled.
- x86_64-linux derivation unchanged; existing output realized successfully
  (not a forced rebuild).
- `git diff --check` passes.
- Full Xfce ISO validation remains pending independent fixes.

```sh
nix-build . -A rsync --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A rsync --argstr system x86_64-linux
```

Prepared with AI assistance; operator review required before submission.
