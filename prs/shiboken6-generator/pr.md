## python3Packages.shiboken6-generator: fix array extent type on 32-bit

Use std::size_t, the extent type of std::array, instead of unsigned long in lookupEnum. On i686 those are distinct types, so template argument deduction fails. No generator features or tests are disabled.

### Validation

- Reproduced i686 build failure before the change.
- Full package builds pass on i686 and x86_64 in the integration stack.
- Package build success is not a claim that every downstream GUI or multimedia runtime path was tested.

```sh
nix-build . -A python3Packages.shiboken6-generator --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A python3Packages.shiboken6-generator --argstr system x86_64-linux
```

Branch contains only this fix on a238bac4849a79e151329cdc51638d3bc7627c6c.
LXQt/LibreOffice validation is still in progress, with additional dependency fixes.

Prepared with AI assistance; operator review required before submission.
