## qt6.qtmultimedia: complete the i686 scalar audio fallback

The existing i686 CMake fallback disables SIMD in PFFFT but not Resonance Audio. Add DISABLE_SIMD to the same architecture-specific target options so the supported scalar implementation is used without requiring SSE on the i686 baseline. Other architecture branches are unchanged.

### Validation

- Reproduced i686 build failure before the change.
- Full package builds pass on i686 and x86_64 in the integration stack.
- Package build success is not a claim that every downstream GUI or multimedia runtime path was tested.

```sh
nix-build . -A qt6.qtmultimedia --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A qt6.qtmultimedia --argstr system x86_64-linux
```

Branch contains only this fix on a238bac4849a79e151329cdc51638d3bc7627c6c.
LXQt/LibreOffice validation is still in progress, with additional dependency fixes.

Prepared with AI assistance; operator review required before submission.
