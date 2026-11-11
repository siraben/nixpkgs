## google-cloud-cpp: tolerate nanosecond rounding in limiter tests

### Description of changes

Keep the rate-limiter tests enabled, but allow up to 4 ns error in four
floating-point duration assertions. On i686/x87, division by the binary
approximations of 0.8 and 1.3 followed by duration_cast produces differences of
1–3 ns from the exact millisecond expectations. Three successive updates
accumulate rounding loss.

The test patch preserves each expected value and checks its absolute error;
it changes neither the limiter implementation nor its control-flow assertions.

### Validation

- Baseline i686 build fails in RateCanDecreaseIfNoThrottlingSinceLastUpdate
  and UpdateClampsMaxFactor, showing 1, 2, or 3 ns differences.
- Patched i686: all 521 enabled CTest targets pass.
- Patched x86_64: all 521 enabled CTest targets pass.
- The previously failing bigtable_internal_mutate_rows_limiter_test passes
  on both architectures. No additional tests are disabled.
- Xfce ISO builds; live and installed desktop boot verified with the integration stack.

```sh
nix-build . -A google-cloud-cpp --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A google-cloud-cpp --argstr system x86_64-linux
```

Prepared with AI assistance; operator review required before submission.
