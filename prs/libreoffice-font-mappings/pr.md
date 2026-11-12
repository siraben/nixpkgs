## libreoffice: share font-file mappings between HarfBuzz faces

Reuse the existing reference-counted FreetypeFontFile mapping for ordinary
HarfBuzz faces, TTC faces and named variable instances, as already done for
FD-backed fonts. Retain filename loading fallback if mapping fails.

A small Writer document failed a 1 MiB vector reserve at approximately 4 GiB
virtual size, with only 240 MB resident. Repeated mappings of Noto CJK font
collections consumed over 3 GiB across ~84 faces. The 97,412-byte document was
not an intrinsically oversized 32-bit fixture.

### Validation

- GDB and a diagnostic shared-blob interposer establish duplicate mapping as
  the allocation cause. The interposer is NOT the production patch.
- Actual VCL rebuild/link with the source patch, no interposer: isolated
  regression and all **87 sw_uiwriter3 tests pass**.
- Supported-driver follow-up also passes the PDF regression and all 3 font
  embedding tests. x86_64 integration package build/unitcheck/slowcheck pass;
  wrapped version and headless FODT→PDF/text smoke pass.
- Independent review checked Map/Unmap balance, HB ownership, manager lifetime,
  normal shutdown, existing locking and FD handling. No concrete new issue found;
  this is not a general thread-safety guarantee.

Whole LibreOffice i686 remains unsuccessful: 35 other CppUnit failures plus UNO
remain. Integration/component validation is not a BASE-only focused build.
No Java restoration, CPU/tolerance/test-selection change, physical hardware or
complete app-feature claim. All unrelated speculative changes remain unstaged.

Evidence: `parallel/lo-writer-diagnosis/{diagnosis.md,font-mapping-summary.json}`,
`parallel/lo-font-cache-validation/{stage-status.tsv,font-fixes-final-review.md,x64-package-check-evidence.json,x64-runtime-smoke/passed.json}`,
`lo-font-cache-source-validation-resume1.{json,log}` and
`libreoffice-x86_64-font-repairs.json` (full original logs retained locally).

Focused branch is one commit on BASE containing this patch plus stable-list
insertion only; it does not depend on the adjacent driver-insertion context.
Current upstream renamed the face source; this patch targets packaged 26.8.
Prepared with AI assistance; operator review required. No PR opened automatically.
