## bcachefs-tools: widen timestamp magnitude on 32-bit

### Description of changes

In `time_from_timespec`, widen `ts.tv_sec.unsigned_abs()` to u64 before passing
it to `Duration::from_secs`. time_t is 32-bit on i686, so unsigned_abs returns
u32 there; Rust does not implicitly widen it. On a 64-bit time_t this remains
an identity conversion. This preserves the existing pre-epoch time handling.

### Validation

- Original i686 build fails at src/commands/fusemount.rs with expected u64,
  found u32.
- Fixed i686 and x86_64 builds succeed.
- Installed version checks pass (1.39.7), as do udev rule checks.
- Existing `doCheck = false` is unchanged: the filesystem suite requires a
  loaded bcachefs module and has not been run here.
- Xfce ISO builds; live and installed desktop boot verified with the integration stack.

```sh
nix-build . -A bcachefs-tools --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A bcachefs-tools --argstr system x86_64-linux
```

Prepared with AI assistance; operator review required before submission.
