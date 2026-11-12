## libreoffice: prefer the supported AFDKO driver

AFDKO 5's `makeotfexe` entry point prints a migration notice and exits 1.
Prefer supported `makeotf` in configure discovery; retain the legacy executable
as fallback when the driver is absent. Stable-version patch only. Existing
caller arguments and configure regeneration remain unchanged.

### Validation

- GNU/Clang copied font artifacts with both AFDKO tool widths: eight normalized
  conversion comparisons agree using the supported driver.
- Actual embeddedfontsafdko.cxx recompilation and VCL link verified, not merely
  a generated-header edit or zero-exit make.
- Formerly timed-out embedded-PDF regression passes; full Writer 87 and font
  embedding 3 suites pass in the independent i686 component validation tree.
- x86_64 integration package build and enabled unitcheck/slowcheck pass; wrapped
  version and headless FODT→PDF conversion/text extraction pass.
- Independent source/ownership/style review: no concrete defect found.

This is **not a successful whole LibreOffice i686 build**: 35 other CppUnit
failures plus UNO remain. Validation includes the separate mapping-cache repair
and other pending integration settings; no BASE-only focused-branch build claim.
No Java restoration, CPU baseline change, test/tolerance suppression or complete
GUI/feature validation. Rejected experiments remain uncommitted/preserved.

Evidence: `parallel/lo-font-cache-validation/{driver-stage-status.tsv,font-fixes-final-review.md,x64-package-check-evidence.json,x64-runtime-smoke/passed.json}`,
`lo-supported-font-driver-recheck.{json,log}`, and
`libreoffice-x86_64-font-repairs.json` (full original log retained locally).

Focused branch contains only this driver patch and stable-list insertion.
Existing upstream AFDKO5 support commit dce3608001d1 was inspected; the configure
preference was not repaired there. This does not claim comprehensive duplicate
clearance. Prepared with AI assistance; operator review required. No PR opened.
