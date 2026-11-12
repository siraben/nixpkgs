## Review

Scope: only `share-font-file-mappings.patch` and `prefer-makeotf-driver.patch`, plus their stable-only insertion. Read-only review; no commands, builds, tests, or edits performed.

Source paths below refer to packaged 26.8.0.3; changed-line references use the independent patched component tree.

- **Correct — mapping/reference balance:** `vcl/unx/generic/glyphs/freetype_glyphcache.cxx:341–351` retains one successful `Map()` reference per HB blob, released by its destroy callback. Failed mapping is balanced with `Unmap()` before the filename fallback. This matches `Map()`’s unconditional reference increment and `Unmap()`’s last-reference release (`:102–159`).

- **Correct — ownership:** `GetHbFace()` retains the existing HB face/blob ownership sequence (`freetype_glyphcache.cxx:355–365`, patched). `PhysicalFontFace::~PhysicalFontFace()` destroys its HB objects (`vcl/source/font/PhysicalFontFace.cxx:56–62`). Sharing the buffer does not tie its release to one TTC face or FreeType face.

- **Correct — manager lifetime:** files remain manager-owned across font-cache clearing: `ClearFontCache()` clears only font information, while `FindFontFile()` retains and reuses filename-keyed file objects (`vcl/unx/generic/glyphs/glyphcache.cxx:41–65`). Normal shutdown clears screen font collections/cache before deleting SalData and its manager (`vcl/source/app/svmain.cxx:587–609`). No new dangling-owner path identified.

- **Correct — locking/FD behavior:** this extends the existing FD-backed HB mapping pattern, without introducing asynchronous work or new callers. Existing font initialization asserts SolarMutex ownership (`vcl/source/outdev/font.cxx:664–695`). The file counter remains non-atomic; this is not a general thread-safety guarantee, but no concrete newly reachable race was found. The existing duplicate/open, fstat-error close, mmap and close handling remains unchanged (`freetype_glyphcache.cxx:102–144`); the supplied FD is not closed.

- **Correct — supported AFDKO selection:** `configure.ac:13174` changes only preference order, retaining legacy fallback when `makeotf` is absent. The installed AFDKO 5 wrapper explicitly exits 1 (`afdko/_deprecated.py:446–472`); the caller already supplies driver-compatible arguments (`vcl/source/gdi/embeddedfontsafdko.cxx:335–386`). Package configure regeneration exists (`default.nix:655–657`).

- **Correct — scope/style:** both changes are small and focused. Their insertion is within `variant == "stable"` (`default.nix:380–386`). Neither patch changes APIs, CPU requirements, tolerances, or test selection. No style-driven rewrite is warranted.

### Validation evidence and limits

- `driver-stage-status.tsv:1–4` records successful caller recompilation and focused suites. Actual recompilation appears in `lo-supported-font-driver-recheck.log:7–8`.
- Component logs report Writer **87 passed**, PDF regression **1 passed**, and font embedding **3 passed** (`sw_uiwriter3.test.log:15048`, `sd_export_tests.test.log:67`, `sd_font_embedding_tests.test.log:57`, under the validation tree).
- The x86_64 package log applies both patches, selects `makeotf`, and invokes `unitcheck slowcheck` (`libreoffice-x86_64-font-repairs.log:416–422,1117,48547–48551`); its JSON records exit 0. This includes other pending changes, not an independent baseline-plus-font-only build.
- No wrapped runtime-smoke result is claimed. The unresolved i686 35 CppUnit failures plus UNO failure prevent whole-package approval.

- **Fixed:** None; read-only review.

No issues found.

- **Merge verdict: OK with notes.** These two narrow patches are publishable with the stated component/integration limits. No required production-code correction identified. Approval excludes the whole package, Java gate, Box2D/skcms, portable32 tests, and devirtualization/excess-precision settings.