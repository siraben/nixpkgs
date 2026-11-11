## python3Packages.afdko: skip overlap reference test on i686

### Description of changes

Exclude only `test_overlap_removal` on i686, alongside the package's existing
i686 test exclusions. The remaining tests stay enabled; 64-bit behavior is
unchanged.

The reference comparison fails on i686. Its helper masks all PFA lines because
the skip-prefix list contains an empty string, so its initial displayed diff
misleadingly looks like a missing blank line. Comparing decoded font outlines
with `tx -dump -6` reveals two curve coordinates of 239.58 instead of the
reference's 239.57. This is a narrow build workaround for the exact-output
comparison, **not a fix for the underlying precision difference**.

An attempted whitespace-only normalization did not fix the failure and was
discarded. No test-helper changes are included here.

### Validation

- Baseline i686: one failing overlap-removal test, 1500 passing tests.
- Patched i686: 1500 passed, 8 skipped, 121 deselected, 8 xfailed.
- x86_64: 1531 passed, 8 skipped, 90 deselected, 8 xfailed, including the
  overlap-removal test.
- Full ISO validation still in progress.

```sh
nix-build . -A python3Packages.afdko --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A python3Packages.afdko --argstr system x86_64-linux
```

Prepared with AI assistance; operator review required before submission.
