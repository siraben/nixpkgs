## isa-l: fix benchmark output-size pointers on 32-bit

### Description of changes

The igzip benchmark stores `deflate_size` as size_t, then passes its address to
four helpers declared with uint64_t pointers. GCC rejects those calls on i686;
merely suppressing the diagnostic could allow an eight-byte write into a
four-byte field.

Use size_t pointers consistently in these benchmark helpers. The buffer is
allocated using a size_t length; the compressed output size cannot exceed it.
The library ABI is unchanged.

### Validation

- Baseline i686 reproduces four incompatible-pointer-type errors.
- Patched i686 and x86_64 builds succeed with checks enabled.
- i686: all 17 CTest targets pass.
- Installed igzip version checks pass.
- Existing update PR #584375 does not include this source fix; it is a separate
  issue from the version update.
- Xfce ISO builds; live and installed desktop boot verified with the integration stack.

```sh
nix-build . -A isa-l --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A isa-l --argstr system x86_64-linux
```

Prepared with AI assistance; operator review required before submission.
