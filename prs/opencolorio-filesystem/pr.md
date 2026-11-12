## opencolorio: preserve minizip-ng usage requirements

Select minizip-ng's installed CMake configuration explicitly and forward
`PC_minizip-ng_CFLAGS_OTHER` when the finder uses pkg-config instead.
An imported library path alone loses public compiler requirements.

With the separately prepared minizip-ng public-wide-file ABI transition,
OpenColorIO must compile its stat and returned-dirent consumers with the same
`_FILE_OFFSET_BITS` mode. Tiny LUT files and directories on this filesystem
have inode numbers above UINT32_MAX; narrow calls fail with EOVERFLOW.
This is not a large-file/resource-limit test exclusion.

### Validation

- Actual i686 OCIO projects through installed config and deliberately forced
  pkg-config discovery each pass **all 10 CTest entries**, including archive
  caching and Python tests.
- Installed compile-command evidence confirms metadata-derived FILE64 on
  Platform.cpp, OCIOZArchive.cpp and ocioarchive, with no ambient/private
  FILE/TIME flags.
- Production x86_64 package builds and passes **all 10 CTest entries**.
- Installed-consumer positive and negative controls distinguish correct
  propagation from the old flag-dropping finder.
- Independent contract/style review found no concrete issue.

**Limits:** i686 full-suite passes use an explicitly labelled SSE2 comparison
based on existing #536904 (Michael Wang/zwang20). This patch does not carry that
CPU change or duplicate that PR. Generic-x87 compilation/accuracy remains a
separate unresolved issue. No arithmetic/tolerance/check-selection changes;
no successful generic-i686 OCIO/Krita, ARM, playback or closure-wide claim.
The 32-bit filesystem repair depends on the separate minizip public contract;
this finder-only branch on otherwise unmodified BASE has not been independently
built. Tests above used the integration stack.

Evidence: `opencolorio-i686-public-lfs-{config,pkgconfig}.{json,log}`,
result `nix-support/file-abi-compile-evidence.json`,
`opencolorio-x86_64-public-metadata.{json,log}` and
`parallel/minizip-public-validation/final-review.md`.

Prepared with AI assistance; operator review required before submission.
No PR opened automatically.
