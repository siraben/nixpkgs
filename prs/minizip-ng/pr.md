## minizip-ng: publish a wide-file ABI on 32-bit GNU/Linux

On a high-inode filesystem, the i686 library's narrow stat/readdir calls fail
with EOVERFLOW. OpenColorIO consequently creates archives containing only the
config, silently omitting its LUT files.

Add an explicit upstream-style `MZ_FILE_OFFSET_BITS_64` option and enable it
only on 32-bit GNU/Linux. One public definition list drives library compilation,
installed CMake usage requirements and pkg-config Cflags, for normal and
compatibility variants. Preserve existing private definitions and feature/test
selection. Reject conflicting explicit FILE32/wide requests instead of silently
overriding one.

**This is a coordinated 32-bit ABI transition.** `mz_os_read_dir` exposes libc
`struct dirent *`; rebuild consumers with matching metadata. Old narrow binaries
are not compatible. Raw consumers must supply the documented definition before
system headers. Do not mix incompatible same-SONAME variants. No `_TIME_BITS`
change is made; this does not fix time32/Y2038 limitations.

### Validation

- Fresh i686 normal and compat builds: **168 tests pass each**.
- **16 C/C++ installed consumers** pass on directory inode 4303727531 through
  CMake, pkg-config, raw compiler usage and both OpenColorIO finder paths.
  No manually injected LFS flag; pointer=32, off_t/ino_t=8, time_t=4.
- Negative controls reject old private-wide metadata and the original OCIO
  fallback that dropped compiler flags.
- Explicit legacy FILE32 configuration succeeds with wide mode OFF; requesting
  both modes fails with the intended conflict error.
- Normal and compat **x86_64 derivation hashes are unchanged**.
- Both actual OCIO project discovery paths pass 10 CTest entries and have
  compile-command proof of metadata-derived flags. These use a separate,
  explicitly SSE2-labelled CPU comparison; they do not establish generic-x87
  accuracy or change this patch's CPU baseline. OCIO finder propagation is a
  separate focused repair.
- Independent ABI/style review: no concrete issue found; limitations retained.

The focused branch was independently evaluated/built on otherwise unmodified
BASE: both variants resolve to the exact previously validated integration
outputs (cache reuse, not a second execution of 168 tests). Evidence:
`parallel/minizip-public-validation/focused-branch-passed.json`.
Two additional C/C++ probes using pinned Dolphin's actual discovery helper pass
high-inode runtime and metadata-derived compile-command assertions; this is
not a Dolphin application build. No ARM runtime/cross-build, physical hardware,
complete downstream app build, or closure-wide compatibility claim. Pinned source inspections found no additional
proven width-changing interface mismatch, but are not exhaustive certification.

Evidence: `minizip{,-compat}-i686-public-contract.{json,log}`,
`parallel/minizip-public-validation/{passed.json,option-guards/passed.json,final-review.md}`,
`audit/minizip-{before,after}-public-contract.json` and source audits under
`parallel/minizip-consumer-source-audit/`.

Prepared with AI assistance; operator review required before submission.
No PR opened automatically. Existing unrelated `_FILE_OFFSET_BITS` history was
inspected; no matching open Nixpkgs minizip PR found in the recorded search.
