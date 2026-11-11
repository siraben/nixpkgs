## liborcus: tolerate floating-point rounding in numeric parser test

The numeric parser uses pow/division; x87 intermediates need not compare bit-for-bit with a double literal. Allow one double epsilon of relative error in the finite-result test. NaN and infinity are rejected for finite expected values; expected zero still requires zero. Keep every valid/invalid input fixture and all suites enabled. No parser runtime change.

### Validation

- Reproduced i686 build failure before the change.
- Full package builds pass on i686 and x86_64 in the integration stack.
- All five test groups pass on both architectures: 22 + 16 + 1 + 8 + 12 tests (59 total).

```sh
nix-build . -A liborcus --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A liborcus --argstr system x86_64-linux
```

Branch contains only this fix on a238bac4849a79e151329cdc51638d3bc7627c6c.
LXQt/LibreOffice validation is still in progress, with additional dependency fixes.

Prepared with AI assistance; operator review required before submission.
