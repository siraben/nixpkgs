## iniparser: enable 64-bit integer assertions on 32-bit

### Description of changes

Building iniparser 4.2.6 on i686-linux fails its `getint64` and `getuint64`
tests with `Unity 64-bit Support Disabled`. Unity auto-detects 64-bit assertion
support from the target's native integer types, so it needs an explicit
`UNITY_SUPPORT_64` when testing these APIs on a 32-bit host.

Set this define for both iniparser's test runner and its private Unity library
on 32-bit hosts. Keep iniparser's tests enabled. The existing Unity doCheck
setting is unchanged. No flags or derivation changes on x86_64-linux.

Found while rebuilding the Xfce i686 installation ISO.

### Validation

- Baseline i686 build reproduced both assertion-support failures.
- Fixed i686 build passes both CTest suites (test_iniparser, test_dictionary).
- x86_64-linux derivation identical before/after; existing output realized
  successfully (not a forced rebuild).
- `git diff --check` passes.
- Xfce ISO builds; live desktop, offline installation and disk-only desktop boot verified with the integration stack.

Commands, from the branch checkout:

```sh
nix-build . -A iniparser --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A iniparser --argstr system x86_64-linux
```

Prepared with AI assistance; operator review required before submission.
