## python3Packages.dask: make tests portable to 32-bit

### Description of changes

Make the tests portable rather than disabling the suite:

- Use explicit int64 indices/group keys where partition reductions and Parquet
  produce int64, instead of relying on NumPy's native-width default.
- Compare memory-usage counts independently of their int32/int64 dtype.
- Derive scalar repr expectations from np.intp.
- Check repartition byte budgets and split/merge behavior rather than hardcoded
  partition counts dependent on RangeIndex/interpreter memory overhead.
- Include i686 in the existing upstream x86 categorical-concat xfail (#10558).
- Exclude only test_take_large on 32-bit: it materializes a 200-million-element
  int64 chunk, requiring a contiguous 1.49 GiB allocation in a constrained
  32-bit address space.

No production Dask code is changed.

### Dependency and validation context

**Requires the separate pandas Arrow-label fix** from
`siraben/i686-pandas-20261111` to resolve seven genuine nullable-string join
failures. Validation was performed in the combined i686 integration stack,
which also includes the separately prepared fixes for build dependencies.
This focused branch contains only the Dask test changes on the pinned base;
it is not a claim that unpatched dependencies build independently.

- After pandas fix, baseline Dask still had 17 failed / 16027 passed tests.
- With portable expectations:
  - i686: **16041 passed, 1105 skipped, 496 xfailed, 1 xpassed**.
  - x86_64: **16056 passed, 1091 skipped, 495 xfailed, 2 xpassed**.
- No unexpected test failures; non-strict xpasses are inherited upstream marks.
- Full ISO validation still in progress.

```sh
nix-build . -A python3Packages.dask --argstr system i686-linux --option extra-platforms i686-linux
nix-build . -A python3Packages.dask --argstr system x86_64-linux
```

Prepared with AI assistance; operator review required before submission.
