# Code Context

## Files Retrieved
Exact roots: S=/nix/store/2ywir6xhl7nlyyayqvgh7f1bxw9pkg59-source; R=/home/siraben/i686-iso-work/refresh-20261111.
1. `R/parallel/ocio-numerical-review/aces2_public_probe.cpp` (64-152): exact cyan words, tolerance and independently recomputed cumulative prefixes.
2. `R/opencolorio-aces2-public-i686-scalar.log`, `R/opencolorio-aces2-public-x86_64-scalar.log`, `R/opencolorio-aces2-public-i686-float-store.log`, `R/opencolorio-aces2-public-i686-clang-x87.log` (each 10-19): cyan evidence.
3. `S/src/OpenColorIO/transforms/builtins/Displays.cpp` (480-491): XYZ→P3 matrix then PQ.
4. `S/src/OpenColorIO/transforms/builtins/ACES.cpp` (500-564): view construction, clamps and matrices.
5. `S/src/OpenColorIO/ops/fixedfunction/FixedFunctionOpCPU.cpp` (1101-1170, 2050-2117): ACES2 forward/inverse and scalar PQ.
6. `S/src/OpenColorIO/ops/matrix/MatrixOpCPU.cpp` (254-280, 323-390): scalar matrix accumulation.
7. `S/src/OpenColorIO/ops/fixedfunction/ACES2/Transform.cpp` (345-380, 920-954, 1005-1142): tone inverse singularity, gamut discriminant, remapping and inverse approximation.
8. `S/src/OpenColorIO/ops/range/RangeOpCPU.cpp` (90-125): NaNs explicitly become lower bound.
9. `R/failures/opencolorio-clang-x87-summary.json` (1-52, 363-379): aggregate counts, integer alpha samples and actual SDRwhite failures.

## Key Code / Architecture
Display forward: XYZ D65→P3 D65 matrix → `Renderer_LIN_TO_PQ<float>`; inverse reverses order/directions.
View forward: AP0→AP1 → clamp → AP1→AP0 → `Renderer_ACES_OutputTransform20::fwd` → clamp → limiting-P3→XYZ. White/linear scaling inactive here. Inverse reverses ops; clamps do not restore lost information.
ACES2 forward: RGB→Aab→JMh → tone/chroma compression → gamut compression → Aab→RGB. Inverse performs RGB→JMh, gamut inverse, tone/chroma inverse, RGB reconstruction.
Matrix red row accumulates float-coefficient products `r*c1 + g*c2 + b*c3`; cyan→red conversion entails cancellation.
PQ uses `L=abs(v*0.01)`, `y=pow(L,m1)`, `N=pow((c1+c2*y)/(1+c3*y),m2)`, then signed float storage. Near-black sensitivity can magnify small linear residuals; zero maps to approximately 7.3e-7.

## Facts: HDR4000 Cyan
Input words are `00000000 3f661134 3f661134 00000000`; original tolerance 0.007000000216 preserved.
Generic GCC display-inverse XYZ differs from scalar64 only in green: `41ee053b` versus `41ee053c` (one float ULP). This alone does not establish a defective initial stage.
Generic GCC view-forward XYZ: `(17.9005260468,29.7525272369,42.0248680115)`; scalar64: `(17.9005165100,29.7525310516,42.0248603821)`.
Final red: GCC generic 0.00970779825 fails; scalar64 7.30942702e-7 passes.
Clang x87 cyan **passes**, red 0.00622071372, with all cyan prefixes bit-identical to GCC float-store. Both first differ from generic GCC at view forward, not earlier printed prefixes. Parent additionally confirms all four Clang HDR4000 samples pass; this is not whole-package success.
Printed prefixes are each recomputed from original inputs, not chained through the stored printed arrays; their agreement does not prove internal intermediates agree.
Strongest cyan amplification hypothesis: final XYZ→P3 cancellation followed by steep near-black PQ. No saved pre-PQ red proves its sign/magnitude yet. x87 materialization sensitivity and algorithm conditioning can coexist; neither a particular libm call nor a particular ACES2 branch is proven responsible.

## Updated Priority: Actual Clang SDRwhite Blackout
Summary explicitly records two Builtins failures at offset1368, expected `(1,1,1)`, actual `(0,0,0)`: REC709 SDR100 tolerance0.004 (test879), P3 SDR100 tolerance0.001 (test886), per parent profile identification. Do not describe these as failing HDR4000 cyan.
Black output at white calls for a nonfinite/clamp investigation before a small-error cancellation explanation. Source has an explicit hiding mechanism: `RangeMinMaxRenderer::apply` comments “NaNs become m_lowerBound” and clamps each channel; the view has lower bound zero both before and after the fixed function. This makes a nonfinite intermediate a plausible blackout precursor, not a proven cause.
A focused candidate is inverse tone scale (`Transform.cpp:365-373`): `Y=pt.s_2/(powf(pt.m_2/f,1/pt.g)-1)`, with `f` derived from clamped `Z`. Near the endpoint, denominator cancellation can create huge/nonfinite reconstructed luminance. Forward tone scale then computes `Y_in/(Y_in+pt.s_2)`; infinity can produce NaN, and its `std::max(0.f,...)` can already map NaN to zero before the explicit range clamp. Whether SDRwhite reaches this endpoint is unmeasured.
Other unproven candidates: gamut inverse's extra approximation above analytical threshold; `b*b-4*a*c` discriminant in `solve_J_intersect`; remap scale denominator `(reach_offset/gamut_offset)-1`. Do not claim any branch is active for white without values.
No proven local source fix. Neither blanket float materialization nor compiler replacement is established repair.

## Start Here / One Smallest Useful Parent Probe
Given parent's pending public SDR profiles, prioritize **one SDR100 white pixel** through the same four public prefixes, preserving the original comparator. First capture the fixed-function inverse RGB output **before its following AP0/AP1 clamp**, and the forward fixed-function RGB output **before the post-render clamp**, as stored float words plus finite classification. These are the earliest useful boundaries for distinguishing a hidden nonfinite from genuinely finite black; log existing stored values to minimize x87 perturbation.
If inverse output is nonfinite, capture only inverse tone inputs `tonemappedJMh[0]`, `Z`, `f`, `pt.m_2`, and the denominator above, with the matching scalar64 control. If inverse output is finite but forward output nonfinite/zero, inspect that same pixel's forward `Aab[0]`, `J_ts`, and compressed JMh. This is a conditional refinement of one pixel probe, not a broad gate list. Preserve an uninstrumented control because logging can alter spills.
For cyan, defer deeper ACES2 instrumentation: a later fixed-input display-only crossover of saved view-forward XYZ triples, capturing pre-PQ red and binary64 dot-product reference from exact float coefficients, separates input conditioning from matrix/PQ evaluation effects.

## Alpha Classification / Limits
20,895 CPUProcessor optimization assertions share one alpha equality pathway; saved examples are **integer** 32770 versus 32771, not harmless float-display noise. Classify retained line2863's `outValues`/`Converter<outBD>` instantiation and conversion/rounding semantics before proposing a comparator fix. Repetition is not 20,895 separate bugs, but uint16 optimized/reference mismatch remains real evidence requiring diagnosis. Canonical source line numbering differs from retained build; do not substitute it blindly.
No builds, tests, probes, source edits or acceptance decisions performed. Remaining risks: white public reproduction and first nonfinite boundary not yet available; parameter initialization and x87 spills remain possible contributors.

```acceptance-report
{"criteriaSatisfied":[{"id":"criterion-1","status":"satisfied","evidence":"Mapped source and saved prefixes, corrected Clang case attribution, identified explicit NaN-to-zero clamp and scoped SDRwhite probe."}],"changedFiles":["parallel/ocio-numerical-review/x87-source-analysis.md"],"testsAddedOrUpdated":[],"commandsRun":[{"command":"Read-only find/rg/sed of specified source and saved logs","result":"passed","summary":"Confirmed Clang cyan/float-store agreement and SDRwhite summary; located tone denominator and NaN-clamping code."}],"validationOutput":["No builds or tests run; parent owns acceptance."],"residualRisks":["No measured SDRwhite nonfinite boundary or proven local repair.","Instrumentation may alter x87 spills."],"diffSummary":"Report only; production source unchanged.","reviewFindings":["Integer alpha mismatches require retained-type classification; not dismissed as floating equality."],"manualNotes":"Bounded read-only specialist analysis; no compiler adoption or tolerance changes recommended."}
```
