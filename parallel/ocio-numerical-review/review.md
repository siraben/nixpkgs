## Review

**Scope:** Read-only numerical triage of the supplied 14-group/28-assertion diagnostic. No edits, builds, tests, or ref changes performed. Paths below are relative to the supplied OpenColorIO source `O`.

- **Correct:** The revised equality harness adds no tolerance and preserves non-floating comparisons. The retained harness still uses raw subtraction in `OCIO_CHECK_CLOSE_FROM`, explaining why equality materialization does not resolve all fixture failures.
- **Fixed:** None; review-only.
- **Finding:** Several remaining failures have concrete fixture-width problems; others expose stored production arithmetic differences and require reference checks. They cannot all be classified as harmless.

### Per-group classification

**F:** fixture/materialization; **A:** actual arithmetic sensitivity, correctness unresolved; **K:** known filesystem dependency.

| Group and location | Classification, evidence, and smallest next step |
|---|---|
| **Baker / bake_3dlut** — `tests/cpu/Baker_tests.cpp:205–238` | **A / brittle string golden.** Full log differs only at two components: `8.054426 → 8.054425`, `7.904850 → 7.904849`. Production processes a stored `vector<float>` before fixed-six-decimal serialization (`src/OpenColorIO/fileformats/FileFormatResolveCube.cpp:622–640,670–675,731–739`). Not a comparator-literal problem. Capture those underlying floats and compare the log-camera/CDL/gamma chain against a reference before changing the golden. |
| **DynamicPropertyImpl / grading_rgb_curve_knots_coefs** — `tests/cpu/DynamicProperty_tests.cpp:356,370–371` | **A.** Stored coefficients differ by approximately **1, 5, and 1 float ULP**, respectively; materializing expected literals cannot eliminate those differences. Generation uses slope estimation, spline fitting and possible slope adjustment (`…/ops/gradingrgbcurve/GradingBSplineCurve.cpp:335–484,793–856`). Check interpolation, continuity and monotonicity using the original control points, not just coefficient agreement. No evidence yet identifies which arithmetic path is more accurate. |
| **GpuShader / MetalSupport8** — `tests/cpu/GpuShader_tests.cpp:1089–1092,1180` | **A / exact numeric-text golden.** Full log shows knot `0.666666508 → 0.666666567`; several coefficients also change, e.g. `0.347727984 → 0.347727865`. Shader structure is unchanged. This shares the RGB spline-generation seam above, rather than a string-comparison defect. Validate evaluated curves and CPU/GPU consistency before deciding on a narrower golden strategy. |
| **OCIOZArchive / archive_config_and_compare_to_original** — `tests/cpu/OCIOZArchive_tests.cpp:543` | **K.** Supplied known wide-filesystem dependency; excluded from numerical investigation. |
| **OCIOZArchive / extract_config_and_compare_to_original** — `tests/cpu/OCIOZArchive_tests.cpp:629` | **K.** Same exclusion. |
| **OpOptimizers / gamma_comp_test2** — `tests/cpu/OpOptimizers_tests.cpp:1085–1116` | **A; substantive rendering discrepancy.** Both sides are stored float images (`:29–63`), so typed CLOSE will not remove errors `0.000196686` and `0.000260463` versus zero. The fixture already documents cancellation through inverse matrices (`:1107–1109`); the matrices and gamma parameters are in `tests/data/files/gamma_comp_test2.ctf:6–31`. Determine failing pixel/channel indices and compare each pipeline with high-precision evaluation. Optimized versus unoptimized agreement is not itself an accuracy oracle. |
| **OpOptimizers / dyn_properties_prefix** — `tests/cpu/OpOptimizers_tests.cpp:1493–1535` | **F, high confidence for this assertion.** Logged nominal floats differ by `9.536743e-7`, **inside the unchanged strict `1e-6f` threshold**. The unmaterialized decimal `4.5947948f` instead differs from actual by about `1.00346e-6`. Try typed CLOSE first. Separately verify the stored LUT endpoint against `2 × 2^1.2`; do not infer production accuracy solely from the assertion passing. |
| **ExposureContrastRenderer / log** — `tests/cpu/ops/exposurecontrast/ExposureContrastOpCPU_tests.cpp:36–52,197–202` | **F plus real rounding-order sensitivity.** The helper multiplies double exposure and log step **before** casting; production multiplies float exposure by a stored float step (`…/exposurecontrast/ExposureContrastOpCPU.cpp:574,579–584`). Thus exact equality compares different algorithms. The observed differences are stored-output differences, not merely literal comparison. Align the helper’s declared rounding/cast boundaries with production, retaining exact comparison; investigate any residual cancellation separately. |
| **GammaOpCPU / apply_moncurve_mirror_style_fwd** — `tests/cpu/ops/gamma/GammaOpCPU_tests.cpp:637–699` | **A.** Expected and actual are stored float arrays; failures are ±blue at inputs `0.75` and `1.5`. Blue parameters are `{2.0,0.4}`. Production evaluates `pow(pixel*scale+offset,gamma)` (`…/gamma/GammaOpCPU.cpp:707–735`), allowing different intermediate rounding from strict float arithmetic. Compare both the ideal model and the stored-renderer-parameter model before prescribing a rounding boundary. |
| **GammaOpUtils / compute_params_reverse** — `tests/cpu/ops/gamma/GammaOpUtils_tests.cpp:30–40` | **F hypothesis, strong but unconfirmed.** `Params` is `vector<double>` (`…/gamma/GammaOpData.h:78`), initialized with `0.1f`; this is another float-literal-to-double seam. For gamma 2, production slope simplifies to `(1+o)²/(4o)` (`…/gamma/GammaOpUtils.cpp:94–101`). Using nominal float `o` versus decimal/double `0.1` crosses a float rounding midpoint. Dump stored `gParams[1]` and `rParams.slope` before changing expectations. |
| **LogOpCPU / cameralin2log_test** — `tests/cpu/ops/log/LogOpCPU_tests.cpp:508,542,562,572,578` | **F, high confidence.** Stored and nominal expected float both print `-24.60000038`; raw decimal excess differs by about `3.8147e-7`, exceeding `1e-7`. Typed CLOSE should compare materialized original operand types using the **same strict `<` and original tolerance**. No production change indicated by these five failures. |
| **MatrixOpData / offsets4** — `tests/cpu/ops/matrix/MatrixOpData_tests.cpp:103–109` | **F, high confidence.** Input is `-1e-6f`, but setter accepts and stores **double** (`…/matrix/MatrixOpData.h:182`; `.cpp:650–666`). Log shows stored approximately `-1e-6` versus nominal float `-9.999999975e-7`. Use matching double literals on both sides, or explicitly materialize a float before widening if float promotion is what the fixture intends to test. |
| **MatrixOffsetOp / create_saturation_op** — `tests/cpu/ops/matrix/MatrixOp_tests.cpp:304–316` | **F, high confidence.** Expected `dst` is **double[] initialized with float literals**; actual is float[]. Recorded `42.0389` versus `42.03889847` exposes the retained-precision initialization. Make expected storage float, matching its literals and rendered output; retain `1e-6f`. Typed CLOSE alone cannot repair an already-stored double fixture. |
| **Builtins / aces2_displayview_roundtrip** — `tests/cpu/transforms/BuiltinTransform_tests.cpp:772–904` | **A / P1 unresolved accuracy failure.** Stored cyan input `(0,0.8987,0.8987)` returns red `0.0097077983`, exceeding the existing `0.007` contract. Index 1344 is not in this 4000-nit case’s difficult list. This exercises public processor APIs, though within the source-built test executable. Not a literal/materialization assertion problem. Isolate and reference-check before declaring generic i686 ready. |

### Prioritized parent experiments

1. **P1 — Isolate the ACES2 cyan failure across the shared-library ABI.**  
   Reproduce the exact stored input with `OPTIMIZATION_NONE`, linking the built library rather than including implementation sources. Record outputs after display inverse, view inverse, view forward and display forward.

   Relevant seams:
   - Matrix plus PQ display chain: `src/OpenColorIO/transforms/builtins/Displays.cpp:479–486`.
   - AP1 and post-transform clamps: `…/builtins/ACES.cpp:510–537`.
   - ACES forward/inverse stages: `…/fixedfunction/FixedFunctionOpCPU.cpp:1101–1165`.
   - Approximate inverse gamut handling: `…/ACES2/Transform.cpp:1113–1136`.

   Compare with a matching ACES 2 reference implementation, retaining the same input bits and parameters. Log **linear red before PQ encoding**: near-black PQ can amplify small linear residuals, but that explains sensitivity—not compliance with the existing code-value contract.

2. **P2 — Correct the bounded fixture seams first.**  
   Probe typed CLOSE on LogOpCPU and `dyn_properties_prefix`; correct Matrix expected/input widths. Preserve original operand types, arithmetic promotions, strict inequality and tolerance values. Do **not** substitute `EqualWithAbsError` unchanged: it uses `<=` (`src/OpenColorIO/MathUtils.h:42–44`).

3. **P2 — Resolve the reverse-gamma fixture analytically.**  
   For nominal float `o = 0.10000000149011612`, the gamma-2 slope is approximately `3.02499996312`, rounding to expected `3.02499985695f`. Decimal `o≈0.1` gives approximately `3.025`, rounding to the adjacent float `3.02500009537f`. Their separation exceeds the unchanged `1e-7` tolerance. A stored-input dump can confirm or reject this explanation without guessing.

4. **P1 — Reference-check stored rendering differences.**  
   For mirrored gamma, compare:
   - ideal blue model `((|x|+0.4)/1.4)²`;
   - the expression using stored float scale/offset;
   - strict float versus extended intermediate evaluation.

   For gamma composition, retain the exact stored input bits and evaluate both matrix chains at high precision, including a separate model with production’s narrowed float coefficients (`…/matrix/MatrixOpCPU.cpp:290–320,366–385`). This separates coefficient error, cancellation and gamma amplification.

5. **Use `-ffloat-store` only as a diagnostic.**  
   A focused comparison can reveal sensitivity to nominal variable storage in spline fitting and exposure/contrast. It does not guarantee rounding after every unnamed subexpression, nor repair mixed-width fixtures automatically. Keep `-ffp-contract=on` constant initially. Any subsequent production boundary change needs reference evidence; a global flag has performance consequences and is not an automatic fix.

**ABI caveat:** Tests directly include implementation `.cpp` files—for example Gamma CPU `:5`, Gamma utilities `:5`, ExposureContrast CPU `:5`, Matrix data `:5`. CPU-test CMake also compiles copied production sources rather than linking `OpenColorIO` (`tests/cpu/CMakeLists.txt:25–40,122–125,342–362`). Therefore test-local inlining results must not be assumed identical across the installed public ABI.

- **Merge verdict: BLOCK generic-i686 numerical-readiness sign-off pending the ACES2 and stored-rendering reference checks.** This verdict does not assess or block the separate minizip contract repair. No tolerance inflation, broad skips, or CPU-baseline escalation recommended.