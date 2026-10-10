# Critical shell audit

Branch: `siraben/critical-shell-audit`, based on local `upstream/master` at
`54a369f835c80eaf570da6cc313030c636c290cf`. The prose-audit branch was untouched.

Three fresh-context reviewers inspected stdenv, fetchers, and compiler/linker
wrappers. A fourth inspected generated shell by generating and executing wrappers,
not just linting the generator. All accepted production fixes passed targeted
follow-up review. This was a bounded audit, not an exhaustive Nixpkgs review.

## Fixed P1 findings

| Commit | Issue | Fix and existing test location |
| --- | --- | --- |
| `40af32f37a0d` | `echo` consumed leading linker flags such as `-e`, turning an entry symbol into an input filename. | Use `printf`; regressions in `pkgs/test/cc-wrapper/default.nix`. |
| `20cdfab79b13` | Literal `dir="dir2"` assignments discarded resolved library symlinks, omitting rpaths and causing runtime loader failures. | Resolve absolute/relative links with cycle detection, preserving store spelling; regressions in `pkgs/test/cc-wrapper/default.nix`. |
| `a605364f1f57` | Bash `%q` quoting corrupted control-whitespace arguments in compiler/linker response files. | Shared response-compatible quoting; real compiler/linker regressions in `pkgs/test/cc-wrapper/default.nix`. |
| `bf64355a851c` | Curl exit 18 restarted an unlimited retry loop, preventing mirror fallback. | Five outer attempts per URL; resume/fallback regressions in `pkgs/build-support/fetchurl/tests.nix`. |
| `762a69b44ddd` | xz failures were discarded; corrupted source bytes could be accepted by unpacking. | Ignore only SIGPIPE status 141; valid, truncated, padded, and status-propagation cases in `pkgs/test/stdenv/default.nix`. |
| `c2df59a13e66` | Generated wrappers evaluated shell expressions embedded in literal executable filenames. | Emit `${original@Q}`; generated-wrapper execution cases in `pkgs/test/make-wrapper/default.nix`. |

Each fix includes its own tests in existing infrastructure. There is no new
`shell-safety` directory, registration, or separate test-harness/follow-up commit.
Production shell files match the previously published branch exactly; history and
test placement were cleaned up without changing the fixes.

## Deferred P2 findings

1. `pkgs/stdenv/generic/setup.sh:1341`: source-root detection treats unquoted
   directory names as patterns. A literal `*` directory can be skipped. Quote the
   filename portion; whitespace-delimited inventory ambiguity is separate.
2. `pkgs/stdenv/generic/setup.sh:1597` and other make calls: custom Makefile names
   undergo splitting/globbing. Quote `${makefile:+-f "$makefile"}` consistently and
   cover all phases/probes.
3. `pkgs/build-support/fetchurl/builder.sh`: partial bytes persist across URLs,
   causing valid non-range mirrors to fail with curl 33. Reset the target when
   switching URLs, preserving continuation within a URL.
4. The same fetcher: hashed mirrors write `$out`, but temporary executable-download
   completion chmods `$TMPDIR/file`. Select `$out` before finishing that path.
5. `pkgs/build-support/setup-hooks/make-wrapper.sh:201`: generation-time splitting
   changes tabs/newlines in `argv0` to spaces. Quote the complete expansion without
   changing historical runtime-evaluation semantics.

These are real, unchanged defects, deferred under the report-only P2 policy.
No concrete efficiency finding justified a broad optimization/refactor. Intentional
raw-shell options and documented whitespace-split flags were not labeled injection.

## Validation

- The original eight-case offline suite passed locally and in a full Nix build on
  `compute`, including the Linux bootstrap/toolchain dependency chain. That temporary
  standalone suite was subsequently removed from the branch as requested.
- Independent controls reproduced baseline failures, verified full unpack-hook
  propagation, tested Clang/LLD response parsing, and round-tripped 111 arguments.
  Generated-shell controls executed 812 cases per tested Bash version; the fix
  follow-up passed 13 literal-path and seven argv0-compatibility cases.
- The production files are unchanged from the published, validated version. The
  temporary offline suite was rerun after relocating coverage: all eight pass.
- All updated existing test targets passed on `compute`: compiler wrappers,
  make-wrapper, stdenv xz handling, and fetchurl partial resume/fallback. The
  compiler test linked and ran through absolute, relative, and chained symlinks,
  and retained the spelling of an already-in-store alias. The fixture uses a
  real store library and absolute search paths; initial fixture failures were
  corrected in the owning commit, not appended as follow-up commits.
- Builds, stores, temporary files, caches, and logs are on external `/dev/sdb` at
  `/mnt/HC_Volume_104626384/siraben-shell-audit`. The relocated tests reuse the
  previously rebuilt fixed toolchain; no internal-disk build/store data is used.
- Existing-infrastructure result: exit 0. Remote/local checksums of all four test
  files match. Log: `cleaned-tests/build.log` under that external audit directory.
  Output basenames:
  - `8xvjrci48xi8hksfrskc9crr6lm4c9jn-cc-wrapper-test-gcc-16.2.0`
  - `91f9fr9l0ansin7mjwasajcyv3g864rw-make-wrapper-test`
  - `ad9m86xcw5ycbrzx7030fdsvrxm93w3z-unpack-xz-errors`
  - `fxvxhgpjwcsrgmigs0ydmnl0v4y2mapq-test-fetchurl-partial-2-salted-52hjx3xgnnkw`
  - `y63d87z2a1hcmxw1v5w086ml0lr7g51i-test-fetchurl-partial-5-salted-0xmr7g7knw55`

Merge verdict: OK with notes; six P1 source defects fixed, five P2 findings deferred.

Limits: Darwin/cctools, all cross-platform suites, and every supported Bash/xz
combination were not exercised. Fetcher tests mock transport; initial reproductions
also used real curl against loopback fixtures. No remote/privileged exploit was
established for the generated-shell filename bug.
