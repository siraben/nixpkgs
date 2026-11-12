## tlrender: handle UTF-8 filesystem paths with C++20

GCC 16 defaults to C++20; tlplay does not select another standard. Filesystem
`u8string()` now returns `std::u8string`, incompatible with tlCore's Path and
feather-tk's Action std::string APIs.

Add a small private helper that copies the UTF-8 object bytes into an owning
std::string, with explicit length. Use it for opening, labels and recent-file
serialization. Preserve filesystem UTF-8 conversion on Windows/POSIX rather
than using locale-dependent `path.string()`, lowering standards or disabling
char8_t. No public API or package CPU/feature/test-selection change.

**JSON clarification:** nlohmann 3.12 already converts u8string to JSON string.
The recent-file adapter is consistent boundary normalization, not a proven JSON
bug fix. The initial harness's expected-array negative control was wrong and
is retained; corrected tests verify existing semantics and the genuine C++20
std::string API type incompatibility.

### Validation

- Complete normal x86_64 build passes.
- Complete i686 comparison build passes with an explicitly SSE2-only OCIO
  dependency; no generic-i686 CPU/accuracy claim. DJV builds with that same
  diagnostic stack too.
- Actual patch-applied helper: **32/64-bit × C++17/20** all pass assertions for
  non-ASCII Latin/CJK/supplementary-plane bytes, filesystem roundtrip, menu
  filename, empty path and JSON string behavior.
- Installed i686 tlCore high-inode stat/directory API passes with a deliberately
  narrow off_t4/time_t4 caller; library imports readdir64/stat64. This validates
  its fixed-width public seam, not arbitrary libc-record interoperation.
- Independent final byte-alias/lifetime/style review: no concrete defect found.

Existing upstream GUI suite remains disabled by the original package's X11
requirement; this change adds no skip. No Windows-runtime, GUI/playback,
or closure-wide claim. The focused branch independently builds on otherwise
unmodified BASE for x86_64, producing a distinct artifact:
`parallel/tlrender-cpp20-parent/focused-x64-passed.json` and
`tlrender-focused-x86_64-build.{json,log}`. i686 validation uses the integration
comparison, not an independent generic-i686 BASE build.
Integration-stack results must not be mistaken for generic-i686 OCIO repair.

Evidence: `tlrender-{i686-sse2,x86_64}-utf8-repair.json`,
`tlrender-utf8-width-standard-regressions-retry1.{json,log}`,
`parallel/tlrender-cpp20-parent/{utf8-passed.json,fileinfo-passed.json,final-review.md}`.
Bounded search surfaced no matching upstream/Nixpkgs fix; current-main raw paths
were unavailable, so comprehensive duplicate clearance is not claimed.
Prepared with AI assistance; operator review required. No PR opened.
