## yaml-cpp: fix double serialization on 32-bit

Backport merged upstream [PR #1401](https://github.com/jbeder/yaml-cpp/pull/1401),
commit `ebb85dd462f1d5842f4a059225553ded71c5c5e2`, using a pinned fetchpatch.

Dragonbox produces a 64-bit decimal significand, but ConvertToChars takes
size_t. On i686 it loses the upper 32 bits and emits incorrect digits and
magnitude. Binary-exact 1.23455810546875 incorrectly becomes 1.270590651e-05.
Use uint64_t for the helper parameter. This is a runtime serialization repair,
not a test-tolerance or floating-point-compiler workaround.

### Validation

- Reproduced all three failing emitter tests on baseline i686.
- Full yaml-cpp builds and its complete CTest target pass on i686 and x86_64.
- Original exact precision/string assertions remain unchanged.
- Standalone i686/x87 regression: 15 cases pass after the upstream patch,
  including positive/negative values, rounding carry, zero, infinity and NaN.
- Generic i686 compiler baseline retained, no SSE2 requirement added.
- Krita still needs separate Qt tool/PyQt6/gavl fixes; no Krita success claimed.

```sh
nix-build . -A yaml-cpp --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A yaml-cpp --argstr system x86_64-linux
```

Focused branch on pinned BASE a238bac4849a79e151329cdc51638d3bc7627c6c;
validation used the integration stack. No duplicate upstream fix invented.

Prepared with AI assistance; operator review required before submission.
