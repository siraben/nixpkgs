# Nixpkgs style and idiom review

Review scope: integration changes since a238bac4849a79e151329cdc51638d3bc7627c6c,
including new dependency repairs. This is a manual review, not an independent
reviewer attestation. Formatting is checked separately.

## Sources actually examined

- `pkgs/README.md`, patch purpose, fetching and vendoring guidelines: published
  upstream patches should be fetched; local unpublished changes may be vendored.
- `CONTRIBUTING.md`, focused commit scope and explanatory commit messages.
- `doc/stdenv/stdenv.chapter.md`, patch and substituteInPlace interfaces.
- Merged #570857 (efivar): pinned fetched 32-bit patches, hostPlatform guard.
- Merged #553854 (avahi): narrowly scoped host-platform ABI fix with rationale.
- Merged #565303 (clippy): buildPlatform guard for a build-process limitation.
- Current `stellarium` package: `withQtWebEngine` defaults to
  `lib.meta.availableOn stdenv.hostPlatform qt6.qtwebengine`.
- Current `picard` package: optional Qt inputs and substitutions guarded by
  host-platform availability.
- Existing `pre-commit` pattern/issue #314873: missing native i686 JDK bootstrap.
- Open #575087 inspected: bootstrap-platform metadata, not a Java implementation
  fix. Open #526288 inspected: PySide cross-build work, not these native i686
  availability or generator extent repairs. Do not duplicate either PR.
- Existing #534793 and #558908 retain their authorship and focused scopes.

Retrieved examples are saved in `merged-pr-*.patch` and `*-existing-pr.*`.

## Per-fix review

| Fix | Review conclusion / action |
|---|---|
| iniparser | `env.NIX_CFLAGS_COMPILE` defines the upstream Unity option; host width is the relevant property. Both private library and runner must agree. Keep both settings; add a conventional separating blank line. |
| rsync | Linux AND 32-bit guard matches glibc large-file ABI; replace-fail prevents silent drift. No security assertion removed. Keep. |
| xfsprogs | Correct upstream backport, but vendoring a published patch conflicts with current contribution guidance. Amend to a pinned fetchpatch (upstream uses abbreviated index hashes, so not fetchpatch2). Retain upstream attribution. |
| upower | Complete removal of obsolete patch and reference, rather than adding another bypass. Keep. |
| azurite | buildPlatform, not hostPlatform: compiler runs during build. Uses existing locked JS dependency rather than changing npm lock/hash. Keep. |
| msgspec | Runtime integer types corrected before narrowing; unsigned subtraction avoids signed overflow; timestamp fixtures preserve assertions without time_t dependence. Keep local unpublished patch with purpose header. |
| bcachefs-tools | `.into()` performs portable widening, unlike an architecture-specific type or lossy cast. Precise replace-fail is idiomatic for this one-token edit. Keep. |
| apache-orc | Match existing uint64_t comparison operand, not platform size_t. Precise replace-fail substitution and explanatory comment. Keep. |
| rapidjson | Carried existing PR; i686-only flags, no test removal. Preserve author and avoid stylistic churn to another author's change. |
| isa-l | Caller passes size_t fields, so size_t* is the correct type on both widths. Substitution is short and fail-checked. Keep. |
| google-cloud-cpp | Test-only bounded 4 ns tolerance, preserving every assertion. Local patch justified, no global fast-math or test disable. clang-format 21.1.8 with upstream style leaves changed source unchanged. |
| Linux TCP_AO | Carried existing PR, mkIf keeps Linux config option semantics. Preserve author; do not create duplicate. |
| pandas | Copy necessary before mutation; both exact source occurrences are intended. Runtime fix rather than skipping dependent Dask tests. Keep short fail-checked substitution. |
| Dask | Explicit fixture dtypes, native repr and memory budgets express test intent; existing xfail expanded, only impossible large allocation excluded. Scope and tests documented. Keep. |
| afdko | Single isi686 exclusion added to existing architecture-specific list, with observed precision difference. Honest workaround, not claimed runtime repair. Keep; underlying precision issue remains. |
| kernel dev | Preserve Makefile fragments in existing pruning logic, no unrelated kernel config changes. Real external-module builds validate it. Keep. |
| graphical installer | Lazy platform-dependent optional packages avoid evaluation failures; default packages remain conventional. Clarify browser-selection comment, no broad allowBroken/allowUnsupported bypass. |
| Hyper-V | Conditions match kernel-supported architectures; use existing `platform` local alias in all-hardware rather than repeating hostPlatform. |
| Shiboken generator | std::size_t matches std::array's non-type template parameter; no blanket compiler flags. Keep targeted replace-fail. |
| Qt Multimedia | Complete upstream's existing i686 fallback in the same target branch. Scalar backend preserves generic i686 CPU baseline; no global SSE requirement. Keep. |
| liborcus | Test-only epsilon-scaled comparison; finite-result check rejects NaN/infinity; zero remains exact. All 59 tests pass on each width. Keep. |
| PySide6 | availableOn is preferable to hardcoded architecture; only optional WebEngine/WebView modules gated. Preserve macOS WebView support. Both builds and offscreen widgets pass; committed and pushed. |
| yaml-cpp | Fetch pinned merged upstream PR #1401, preserving uint64_t significands. Exact existing precision tests retained and full CTest passes on both widths. No SSE2 or tolerance workaround. |
| gavl | Same glibc time64/LFS flags pattern as tayga, with an explicit 32-bit GNU guard. Public API uses int64_t rather than libc time/stat types; external consumer HTTP date round trips pass on both widths. |
| Qt5 qmake | Private Unix bootstrap flags, not general compiler flags or public Qt headers; follows the tool build platform. Both full builds pass; installed i686 tool imports wide filesystem APIs and project discovery passes. Committed. |
| Qt6 qmake | Private CMake definition follows existing qt_internal_extend_target idiom, no public QtCore ABI change. Both full builds pass; real installed-tool high-inode regression fails before and passes after. Committed. |
| PyQt6 | Optional PDF default uses availableOn, mirroring existing stellarium/PySide patterns. Both fresh builds/imports/offscreen renders pass after qmake repairs; PDF availability matches architecture. One-line focused commit pushed; explicit overrides preserved, no unsupported-platform override. |
| LibreOffice (pending) | buildPlatform isi686 gate reflects bootstrap compiler location; document optional Java feature loss. Box2D scalar and skcms dispatcher defines remain target-local and x86-32-only. Class-specific refcount override was rejected after another same-root thunk failure; test devirtualization workaround scoped to i686/GNU16, not other architectures/toolchains. Full build validation required before commit. |

Minizip/OpenColorIO public ABI candidates remain uncommitted. Independent review
required public CMake and pkg-config propagation, explicit ABI-transition wording,
no time64 change, and no incompatible private same-SONAME variant. Both minizip
variants and 16 C/C++ consumers now pass; exact source/option and actual OCIO
project gates remain. x86_64 minizip derivations are unchanged. Do not treat
synthetic metadata success as proof of every downstream closure.

PyQt6 integration d6ff01421387 and focused 9c2686c4f13c were committed separately
from all pending source work, pushed and remote-verified. Backup ref:
`backup/i686-before-pyqt6-20261112`. Related #538261 changes no PyQt expression;
no duplicate PR or automatic PR was opened.

## History amendment policy

Preserve backup refs before rewriting. Do not fold unrelated package changes
into one commit. Autosquash style fixups into their original commits, keeping
original author information. Regenerate focused branches on the same BASE,
record old/new hashes, push only with explicit old-hash force-with-lease, and
verify remote hashes. Rebuild changed derivations or demonstrate unchanged
derivation hashes where edits are non-functional. This policy has not yet been
fully executed for pending LibreOffice; the committed fixes were audited,
three changed focused branches were regenerated/pushed with exact leases and
all existing focused trees/remote records checked. Both carried authors are
preserved. All 30 currently changed Nix files pass formatting, including pending
candidates; formatting does not establish their correctness. See report.md and
focused-amendments.json for exact hashes and limitations.
