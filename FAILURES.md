# Initial complete Xfce i686 failure census

Baseline: a238bac4849a79e151329cdc51638d3bc7627c6c, plus graphical ISO
QEMU guest-agent architecture guard and Dillo browser fallback.
Build: xfce-attempt3 (finished with exit 1); logs under failures/.

These are root builder failures, not every downstream failure. Classifications
below are preliminary until individually reproduced/fixed and validated.

| Package | Observed failure | State |
|---|---|---|
| iniparser 4.2.6 | Unity 64-bit assertions disabled | i686 tests passed; x86_64 unchanged; committed 1b00d8d47326 |
| rsync 3.5.0 | partial-protected-regular-retry-linux security test fails | i686 security test passed; x86_64 unchanged; committed 336d9364e315 |
| xfsprogs 7.2.1 | libxfs_trans_mod_sb long versus int64_t declaration mismatch | upstream patch builds on i686 and x86_64; committed 702baa8a4872 |
| upower 1.91.5 | stale i686 patch fails to apply | obsolete patch removed; all 97 tests pass on i686; committed 122c38578034 |
| azurite 3.37.0 | native TypeScript compiler lacks linux-ia32 package | both architectures build; CLI version checks pass; committed 0a4c470d2ca3 |
| msgspec 0.21.1 | enum, huge arrays, and timestamp tests fail | 5834 tests pass on both architectures (379 existing skips); committed 38e8f8ac1818 |
| bcachefs-tools 1.39.7 | Rust mismatched types | both builds and installed version/udev checks pass; committed 6e71c95312de |
| apache-orc 2.3.1 | std::min integer type mismatch | both builds pass; committed bb2ac01f3902 |
| rapidjson | Value.Float test fails | existing PR #534793 passes all 3 i686 CTest targets; x86_64 unchanged; carried as d247b15c76cf, no duplicate PR |
| isa-l 2.32.1 | incompatible pointer types in igzip benchmark | both builds pass; all 17 i686 tests pass; committed 55d54fa8146e (not in update PR #584375) |
| google-cloud-cpp 2.44.0 | two MutateRowsLimiter assertions fail | all 521 enabled CTest targets pass on both architectures; committed b3220af528b4 |

## Second full build (xfce-attempt4)

Ten package branches and the companion PR-drafts branch were pushed and remote
hashes verified. All eleven first-round root failures are resolved in the
integration build. Two newly reached root failures remain:

- Linux 6.18.63 config: mandatory TCP_AO is unavailable on i686. Existing
  #558908 patch passes the config build, carried as 7ccf3b948d3d with author
  credit; no duplicate PR. Full kernel compilation remains pending.
- Python 3.14 dask 2026.8.0: 24 failures among 16020 passed, involving 32-bit
  address-space exhaustion, int32/int64 expectations, and read-only pandas
  arrays. Needs individual diagnosis rather than blanket doCheck=false.
  The read-only arrays were traced to a pandas runtime defect: Arrow's int32
  labels remain read-only on i686 after astype(intp, copy=False). A standalone
  reproducer fails before, and all 8 join mode/sort combinations pass after
  requesting copies on both architectures. Separate pandas commit c9d571066fec
  and branch pushed. Re-running Dask resolved all 7 read-only-array failures.
  Remaining 17 failures are addressed with portable test expectations and one
  address-space-limited test exclusion, committed as d0d2768d19f0. Full suite
  passes: i686 16041 passed / x86_64 16056 passed. See prs/dask/pr.md for exact
  inherited skips/xfails and the dependency on the pandas fix.

Other known/potential blockers:
- TCP_AO: existing upstream PR #558908, do not duplicate.
- Hyper-V modules/guest enablement: earlier fixes may still be required once
  dependencies unblock kernel/initrd build.

Each root fix is to be validated and committed separately. PR drafts and remote
branches will describe only evidence actually established by this new run.
