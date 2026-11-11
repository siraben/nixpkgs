## python3Packages.msgspec: fix 32-bit integer handling

### Description of changes

Fix the underlying failures instead of adding 32-bit test skips:

- Keep compact integer lookup offsets in uint64_t until after the bounds
  check. Narrowing the difference to Py_ssize_t could incorrectly accept an
  invalid enum value on 32-bit. Unsigned subtraction also avoids signed
  overflow when the key and offset span the signed 64-bit range.
- Reject a MessagePack 32-bit length larger than PY_SSIZE_T_MAX with the normal
  truncation error before converting it to Py_ssize_t. Such a payload cannot
  fit in a Python input buffer; previously narrowing could return NULL without
  an exception and cause SystemError.
- Construct three large timestamp test expectations using datetime arithmetic
  instead of datetime.fromtimestamp, avoiding 32-bit time_t limits while
  retaining every encode/decode assertion.

### Validation

- Original i686 build reproduced nine test failures (enum lookup, malformed
  arrays, and large timestamp expectations).
- Patched i686: **5834 passed, 379 skipped**.
- Patched x86_64: **5834 passed, 379 skipped**.
- No new disabled tests or skips. Existing skips are from the upstream suite
  and optional dependencies in the normal Nixpkgs check environment.
- Python import checks pass.
- Xfce ISO builds; live and installed desktop boot verified with the integration stack.

```sh
nix-build . -A python3Packages.msgspec --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A python3Packages.msgspec --argstr system x86_64-linux
```

This is a local source patch, not yet submitted upstream. Upstream review of
the runtime fixes is recommended. Prepared with AI assistance; operator review
required before submission.
