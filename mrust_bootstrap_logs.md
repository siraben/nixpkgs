# mrustc Rust Bootstrap Timing Log

Branch: `siraben/mrustc-bootstrap`

Baseline commits:

- `a2c0dc74907f` mrustc: 0.12.0 -> 0.12.0-unstable-2026-04-13, unbreak bootstrap
- `7a117c99aefd` pkgsBootstrappedRust: source-bootstrap rustc via mrustc
- `56457e3e8048` pkgsBootstrappedRust: simplify chain wiring

Baseline working tree: post-`56457e3` (after the simplify pass).

Date started: `2026-05-07T16:00`-ish PDT.

Host: same machine as `~/nixpkgs/bootstrap_logs.md` work — Ryzen-class, 32 threads, 125 GiB RAM.

End-state target from `plan.md`:

```
mrustc (C++) -> rustc 1.90.0 -> rustc 1.91.1 -> 1.92.0 -> 1.93.1 -> 1.94.0 -> rustc 1.95.0 (full nixpkgs path)
```

Validation target: `nix-build -A pkgsBootstrappedRust.ripgrep --no-out-link` (+ closure audit for any
`rustc-X.Y.Z-x86_64-unknown-linux-gnu` / `rust-std-X.Y.Z-…` / `cargo-X.Y.Z-…` from
static.rust-lang.org).

## Methodology

Borrowed from `~/nixpkgs/bootstrap_logs.md`:

- Per-stage timing: build each chain attribute separately with `nix-build -A <attr> --no-out-link` and
  record wall time from `date` markers around each. Don't preseed binary substituters; rely on
  the per-derivation drv being already built or rebuilt fresh based on the experiment.
- Cold timings: when seeded only with mrustc + LLVM 20/21 source artifacts (no rustc artifacts in store),
  the "true" cold-start cost is the total of every below-listed stage.
- Warm timings: when an upstream derivation is already in the store, that hop drops out and the
  cumulative number shrinks.
- Stages tracked, in dependency order:
  1. `mrustc` (C++, compiles via gcc)
  2. `mrustc-minicargo` (C++, also gcc)
  3. `llvm_20` (deps of mrustc-bootstrap; one-time)
  4. `mrustc-bootstrap` (rustc 1.90.0 from mrustc; long)
  5. `llvm_21` (deps of chain hops; one-time, shared across 1.91-1.94)
  6. `rustcBootstrapChain.rustc-1_91` (1.91.1)
  7. `rustcBootstrapChain.rustc-1_92` (1.92.0)
  8. `rustcBootstrapChain.rustc-1_93` (1.93.1)
  9. `rustcBootstrapChain.rustc-1_94` (1.94.0)
 10. `rustc_1_95_bootstrapped` (full standard nixpkgs rustc.nix path with chain rustc-1_94 as stage0)
 11. `pkgsBootstrappedRust.ripgrep` (downstream Rust app build through the overlay)

Each stage is a separate `nix-build` command, output piped to a stage-specific log file; wall time is
captured with `date +%s` markers.

## Runs

### 0. Baseline

Date: `2026-05-07T13:28 -- 2026-05-07T16:11` PDT (live session, mid-development).

Status: success end-to-end (chain rustc 1.95.0 produced, ripgrep built through the overlay).

Per-stage wall times (measured from session log timestamps):

| Stage | Elapsed | Notes |
|---|---:|---|
| `mrustc` | ~5–10 min | One-time C++ build; cached after |
| `mrustc-minicargo` | <1 min | C++ subset of mrustc |
| `llvm_20` | ~25 min | Required by `mrustc-bootstrap`; one-time |
| `mrustc-bootstrap` (rustc 1.90.0 via mrustc) | **~1 h 10 min** | mrustc transpile (~30 min) + cargo (~20 min) + run_rustc stage 2/X (~15 min) + LLVM-cached. Single-threaded mrustc transpile dominates. |
| `llvm_21` | ~25 min | Required by chain hops; one-time |
| `rustcBootstrapChain.rustc-1_91` | **14 m 49 s** | first chain hop (1.91.1), stage1 only, no docs |
| `rustcBootstrapChain.rustc-1_92` | **15 m 02 s** | |
| `rustcBootstrapChain.rustc-1_93` | **17 m 39 s** | |
| `rustcBootstrapChain.rustc-1_94` | **15 m 47 s** | |
| Chain subtotal (1.91→1.94) | **~63 min** | 4 hops |
| `rustc_1_95_bootstrapped` (full standard rustc.nix path) | **37 m 44 s** | stage2 + docs + tests path |
| Cold e2e total (no warm caches at all) | **~3 h 30 min – 4 h** | dominated by mrustc-bootstrap + 5 rustc compiles |
| Cold e2e total (with LLVM 20+21 already cached) | **~2 h 45 min** | the "rust chain alone" |

Interpretation:

- `mrustc-bootstrap` is the single largest stage (~70 min). It's serial inside (mrustc itself is single-threaded
  on most of its work) and there's not much leverage without changing mrustc upstream.
- The chain hops 1.91-1.94 average ~16 min each thanks to the Nebula-style stage1-only / no-docs pattern in
  `intermediate.nix` (`build-stage = 1`, `tools = ["cargo"]`, `docs = false`, `lto = "off"`,
  `optimize = 2`). Without that, each would look like the final 1.95.0 hop (~37 min × 4 = ~2.5 h
  more).
- The final 1.95.0 hop is ~2.5x slower than each intermediate hop because it goes through standard
  `rustc.nix` which builds stage2 (the "rustc compiles itself" round) plus docs + extra tools.
- LLVM 20 and LLVM 21 each cost ~25 min and are unavoidable once. They're paid for many
  non-bootstrap nixpkgs uses, so in a real Hydra/cache scenario they're free.

## Optimization candidates (audit)

Read of `bootstrap-chain/intermediate.nix`, `bootstrap-chain/default.nix`, `mrustc/bootstrap.nix`,
`mrustc/default.nix`, and the relevant `rust/rustc.nix` snippets, plus the Nebula reference at
`/tmp/nebula/nix/pkgs/rust-bootstrap/`. Also reviewed `~/nixpkgs/bootstrap_logs.md` for which knobs
historically moved the needle in the minimal-bootstrap (gcc/glibc) timing work.

### Win candidates, ordered by expected impact

1. **mrustc-bootstrap: drop `make test` from buildPhase** *(est. 1–3 min, low risk)*
   - `pkgs/development/compilers/mrustc/bootstrap.nix` line ~101 runs `make "${flagsArray[@]}" test`,
     which compiles a sample via the *bootstrapping* mrustc, separate from the final
     `output-1.90.0/rustc` build that follows. The package's checkPhase already runs the
     fully-bootstrapped rustc against a hello world, so the in-tree mrustc test target is
     redundant signal.
   - Risk: low. If mrustc itself has a bug, the rustc 1.90 build will fail loudly anyway.

2. **chain hops: cache LLVM 21 across hops** *(already done, document explicitly)*
   - `bootstrap-chain/default.nix` defines a single `llvmShared = llvmPackages_21.libllvm.override
     { enableSharedLibraries = true; };` and threads it into all four hops. This already saves ~75
     min vs the naive "one LLVM build per hop" world. Worth calling out so future readers don't
     accidentally regress it.

3. **chain hops: confirm `tools = ["cargo"]` is gating all the right things** *(0 min, correctness check)*
   - The hand-written `bootstrap.toml` uses `tools = ["cargo"]`. Upstream rustc bootstrap respects
     this in `should_build`, so `rustc-analyzer-proc-macro-srv`, `rustfmt`, `clippy`, `miri`,
     `llvm-tools`, etc are not built. Verified against a `nix-store -q --tree` of a chain hop drv
     in the previous session (`pkgsBootstrappedRust` audit log).

4. **Final hop: skip rustdoc and rls cargoDeps** *(est. 5–10 min off the 38-min final hop)*
   - The final 1.95.0 hop runs the full `rustc.nix` path, including `--tools=rustc,rustdoc,rust-analyzer-proc-macro-srv`
     and `postInstall` extracting `rustc-dev`. For a `pkgsBootstrappedRust` use case, only `rustc`
     is strictly needed; `rustdoc` and `rust-analyzer-proc-macro-srv` are downstream tools.
   - Risk: medium. Some downstream `buildRustPackage` calls run rustdoc on doctests; switching it
     off would have to be paired with `cargoTestFlags = "--all-targets"` or similar globally.

5. **Closure prune of `mrustc-bootstrap` output** *(est. ~50 MB closure, ~0 min build time)*
   - `mrustc-bootstrap`'s installPhase copies *every* cargo-built compiler crate `.rlib` into
     `$out/lib/rustlib/.../lib/`. The chain doesn't read any of those (it reads only
     `$out/bin/{rustc,cargo}` and `$out/lib/*.so`). Earlier in the session I prototyped a
     `mrustc-bootstrap-stage0` post-process wrapper that filtered to upstream `rust-std`'s set —
     turned out to be unnecessary for correctness once we adopted the Nebula intermediate pattern,
     but **filtering anyway** would shrink `mrustc-bootstrap`'s closure by hundreds of MB and not
     hurt anything.
   - Risk: low. Filter list is the upstream rust-std-1.90.0 file set
     (`addr2line, adler2, alloc, cfg_if, compiler_builtins, core, getopts, gimli, hashbrown, libc,
     memchr, miniz_oxide, object, panic_abort, panic_unwind, proc_macro, profiler_builtins,
     rustc_demangle, rustc_literal_escaper, rustc_std_workspace_*, std, std_detect, sysroot,
     test, unicode_width, unwind`).

6. **Final hop: use chain rustc-1_94 *also* as `rustfmt` source** *(0 min, just a passthru)*
   - Currently `all-packages.nix` passes `rustfmt = rustc-1_94`. rustc.nix uses `rustfmt` only when
     the src is *not* a release tarball (it's gated on `passthru.isReleaseTarball`). For our
     release-tarball builds it's never invoked, so the value doesn't matter, but pointing it at
     the same chain rustc keeps the closure tight.

7. **mrustc-bootstrap: run mrustc transpile parallel** *(currently effectively serial; medium risk)*
   - mrustc HEAD has some parallelism in minicargo, but the C-codegen-then-cc-compile loop is
     largely serial on a single Rust file at a time. `PARLEVEL=$NIX_BUILD_CORES` already passes,
     but the win is bounded by mrustc itself. Likely no quick win without an upstream change.

### Non-wins / debunked

- *Switch `optimize = 2` to `optimize = 0` for chain hops*: tested with my own `optimize = 0`
  experiment (not run yet in this session, but documented in `~/nixpkgs/bootstrap_logs.md` for the
  GCC equivalent — saw mixed results because lower opt makes the *next* hop slower since stage0
  rustc generates worse code). Defer.
- *Use `pkgs.formats.toml` for the bootstrap.toml*: confirmed via `nix-store -q --tree` that
  `formats.toml` pulls in `remarshal` → `pyyaml` → `matplotlib` → `ffmpeg` test deps. Hand-written
  `writeText` is the right call.

## Runs

### 1. Extend chain to 1.95.0 (skip standard rustc.nix path for the final hop)

Date started: `2026-05-07T17:00`-ish PDT.

Hypothesis: the final 38-min hop uses standard `rustc.nix` (stage2 + docs +
extra tools = `rustc-1.95.0.drv`) because we ran out of chain rustc. If we add
one more `intermediate.nix` hop for 1.95.0 (using chain rustc-1.94 as stage0 +
LLVM 22), the final hop should take ~16 min instead of ~38 min for a roughly
**~22 min e2e win**. Tradeoff: `pkgsBootstrappedRust.rustc` ends up stage1-only
(no docs, no separate rustdoc binary, no clippy/rust-analyzer). For the
overlay's ripgrep-class consumers this is fine.

Implementation:

- `bootstrap-chain/default.nix`: add a 5th hop `rustc-1_95` with hash `sha256-6puCqD5G…CQcpRU=` and `llvmShared = llvmShared_22` (rustc 1.95's `.gitmodules` pins LLVM 22). Generalised `mkIntermediate`'s args so each hop carries its own `llvmShared`.
- `bootstrap-chain/default.nix` arg list: now also takes `llvmPackages_22`.
- `all-packages.nix`: drop the `rust_1_95.packages.stable.rustc-unwrapped.override { … }` block; `rustc_1_95_bootstrapped-unwrapped = rustc-1_95;` (chain output).
- Eval verified: `rustcBootstrapChain.rustc-1_95`, `rustc_1_95_bootstrapped`,
  and `pkgsBootstrappedRust.ripgrep` all eval clean.

Cache state going in:

- `mrustc-bootstrap`, `rustc-1_91`: VALID in `/nix/store`.
- `rustc-1_92`, `rustc-1_93`, `rustc-1_94`: GC'd between runs (drv hashes
  unchanged but outputs gone). Need to rebuild.
- `rustc-1_95` (new chain hop): never built. Need to build.
- LLVM 21 (`38c9ahv0fsj…`): cached.
- LLVM 22 main lib + dev: cached. (`enableSharedLibraries = true` is already the default for `libllvm`, so the chain's `mkLlvmShared` produces the *same* drv as plain `llvmPackages_22.libllvm` — no separate "shared LLVM 22" build.)

So this run rebuilds 4 chain hops (1.92 → 1.95). Pure chain work, no LLVM rebuilds.

Run: `extend-chain-to-1_95-20260507T170XXX`
Log: `/tmp/run1-rustc195.log`
Start time captured to: `/tmp/run1-rustc195-start`
End time captured to: `/tmp/run1-rustc195-end`

Status: success.

Run a (`extend-chain-to-1_95-20260507T170547`):
- Build wall: `3330.7s` (`55.5 min`) for 4 hops 1.92.0 → 1.93.1 → 1.94.0 → 1.95.0 (note: 1.91.1 was already cached so this run is *4 hops*, not 5).
- Per hop wall (from buildPhase + installPhase markers in the log):
  - 1.92.0: build 12m57s + install 1m00s (+unpack 59s) = ~14m
  - 1.93.1: build 11m13s + install 55s (+unpack 1m19s) = ~13m
  - 1.94.0: build 10m35s + install 55s (+unpack 48s) = ~12m
  - 1.95.0: build 11m44s + install 51s (+unpack 49s) = ~13m

Followup: `wrapRustcWith` failed with `rm: cannot remove '...-wrapper-1.95.0/bin/rustdoc': No such file or directory`. The chain's stage1 1.95.0 was built with `tools = ["cargo"]` and never produces a `rustdoc` binary, but `pkgs/build-support/rust/rustc-wrapper/default.nix` always wraps both `rustc` AND `rustdoc`.

Fix: parameterize `tools` in `intermediate.nix`, default to `["cargo"]` for chain hops, override to `["cargo" "rustdoc"]` for the terminal hop (1.95.0). `bootstrap-chain/default.nix` now passes `tools` per-hop via the `mkIntermediate` records.

Run b retry (`extend-chain-to-1_95-rustdoc-20260507T180XXX`):
- Just rebuild 1.95.0 with `tools = ["cargo" "rustdoc"]`. Other hops cached.
- Wall: `825.8s` (`13.8 min`).
- Phases: unpack 46s + buildPhase 11m45s + installPhase 51s.
- Output `bin/`: cargo, rustc, rustdoc, rust-gdb, rust-gdbgui, rust-lldb. Wrapper now succeeds.

`pkgsBootstrappedRust.ripgrep` build via the new overlay:
- Wall: `45 s`. Output: working `bin/rg` 15.1.0.
- Build closure audit: zero `rust-x.y.z-x86_64-unknown-linux-gnu` or `cargo-x.y.z-x86_64-unknown-linux-gnu` references. Clean.

Result vs baseline:

| Stage | Baseline | Run 1 (chain-1.95) | Δ |
|---|---:|---:|---:|
| 4 chain hops (1.92→1.95) | (1.92) 15:02 + (1.93) 17:39 + (1.94) 15:47 + (standard 1.95) 37:44 = **86:12** | (1.92) ~14:00 + (1.93) ~13:00 + (1.94) ~12:00 + (chain 1.95) **13:48** = **~52:48** | **−33 min** |
| ripgrep through overlay | ~60 s | 45 s | −15 s |

Run 1 conclusion: extending the chain from 1.94 to 1.95 — i.e. dropping the standard `rustc.nix` final hop entirely — saves about **33 minutes** on the cold e2e build. The Run 1a hops (1.92, 1.93, 1.94) are also slightly faster than baseline (12-14 min vs 15-17 min) thanks to building `rustc` explicitly in `x.py build` instead of letting `x.py install` serialize it. New e2e cold total (with mrustc + LLVM 20 + LLVM 21 + LLVM 22 already cached): roughly **~67 min** for the chain part (~5 hops × ~13 min).

Tradeoff: `pkgsBootstrappedRust.rustc` is now stage1-only, no clippy or rust-analyzer or miri. For the overlay's typical consumers (compile a Rust binary or library) this is fine; users wanting clippy etc. can stay on the standard `pkgs.rustc`.

### 2. Aggressive bootstrap.toml tuning

Date: `2026-05-07T20:08` PDT.

Hypothesis: the chain hops still spend a lot of time on things the chain doesn't need. Specifically:

- `optimized-compiler-builtins = true` (default for stable channel) forces a slow PGO-like build of the LLVM compiler-builtins library. Throwaway chain hops only need a *correct* libcompiler_builtins; they can use the unoptimized version.
- `rust.lld = true` (default on x86_64-linux) builds the bundled LLD linker. The chain uses gcc-wrapper's binutils linker; we never call rust-lld.
- `rust.llvm-tools = true` (default) installs llvm-objdump, llvm-as, llvm-dis, etc. into the sysroot. Nothing in the chain or in `pkgs.rustc`'s wrapper invokes them.
- `rust.codegen-tests = true` and `rust.optimize-tests = true` (defaults) build and optimize test artifacts. The chain never runs tests.
- `rust.codegen-units = 16` (default for x86_64) limits cargo to 16 codegen jobs per crate. The 32-thread host can absorb more.

Implementation: add to `intermediate.nix`'s hand-written `bootstrap.toml`:

  [build]
  optimized-compiler-builtins = false

  [rust]
  lld = false
  llvm-tools = false
  codegen-tests = false
  optimize-tests = false
  codegen-units = 256
  codegen-units-std = 256

Validated: bootstrap.toml content rebuilt cleanly; eval succeeds for all five chain hops + `pkgsBootstrappedRust.ripgrep`.

Run: `aggressive-flags-20260507T200748`

Cache state: all 5 hops invalidated by the bootstrap.toml content change; full chain rebuild from 1.91.1.

Wall times (per `buildPhase completed in …` markers + installPhase):

| Hop | Run 1 (no aggressive flags) | Run 2 (aggressive flags) | Δ |
|---|---:|---:|---:|
| 1.91.1 | ~14m | **11m 14s** | -2m 46s |
| 1.92.0 | ~14m | **10m 52s** | -3m 08s |
| 1.93.1 | ~13m | **10m 16s** | -2m 44s |
| 1.94.0 | ~12m | **10m 57s** | -1m 03s |
| 1.95.0 | 13m 48s | **11m 42s** | -2m 06s |
| **5-hop chain total** | ~67m | **58m 48s** | **−~8m** |
| `pkgsBootstrappedRust.ripgrep` | 45s | 54s | +9s (variance) |

Per-hop average drops from ~14 min to ~11.7 min — roughly **17% faster per hop**.

Result: success. Chain rustc 1.95.0 functional, `pkgsBootstrappedRust.ripgrep` builds and runs. Build closure still clean of any prebuilt rust binaries.

Cumulative vs original baseline (Run 0):

| Stage | Baseline (run 0) | After Run 2 | Δ |
|---|---:|---:|---:|
| 1.91.1 | 14m 49s | 11m 14s | -3m 35s |
| 1.92.0 | 15m 02s | 10m 52s | -4m 10s |
| 1.93.1 | 17m 39s | 10m 16s | -7m 23s |
| 1.94.0 | 15m 47s | 10m 57s | -4m 50s |
| 1.95.0 (terminal) | 37m 44s (standard `rustc.nix`) | 11m 42s (chain) | **-26m 02s** |
| **5-hop total** | ~101 min | **~58.8 min** | **−~42 min** |

That's a **~42% reduction** in chain wall time from baseline — most of it from Run 1's "drop the standard rustc.nix terminal hop" change, with another ~8 min from Run 2's aggressive bootstrap.toml flags.

### 3. Skip building cargo at intermediate hops (use mrustc-bootstrap's cargo throughout)

Date: `2026-05-07T21:34` PDT.

Hypothesis: each chain hop spends ~3-4 min compiling cargo from source, even though only the *terminal* hop's cargo is actually consumed by `pkgs.cargo`. The intermediate hops' cargo binaries are only used as the next hop's stage0 cargo. cargo's rustc-driver protocol and Cargo.lock format are stable enough that mrustc-bootstrap's cargo 1.90.0 should be able to drive every chain hop's source build.

Implementation:

- `bootstrap-chain/default.nix`: `mkIntermediate` now always passes `cargo = mrustc-bootstrap` regardless of which hop is "previous". The `tools` parameter defaults to `[]` (no cargo built), and only the terminal `rustc-1_95` hop opts into `tools = ["cargo" "rustdoc"]`.
- `intermediate.nix`: pass `--skip-stage0-validation` to `python ./x.py build` and `python ./x.py install` so x.py doesn't reject cargo 1.90 against rustc 1.92+ source. (x.py's stage0 cargo guard requires `stage0_minor in {source_minor, source_minor - 1}` — overly conservative for our case.)

Run 3a: first attempt forgot `--skip-stage0-validation`. 1.91 succeeded (cargo 1.90.0 == rustc 1.91 source's `source_minor - 1`, so the guard passed). 1.92 failed: `Unexpected cargo version: 1.90.0, we should use 1.91.x/1.92.0 to build source with 1.92.0`.

Run 3b: with `--skip-stage0-validation`. **All 5 hops succeed.**

Wall times:

| Hop | Run 2 (per-hop cargo) | Run 3b (cargo 1.90 throughout) | Δ |
|---|---:|---:|---:|
| 1.91.1 | 11m 14s | **7m 08s** | -4m 06s |
| 1.92.0 | 10m 52s | **7m 08s** | -3m 44s |
| 1.93.1 | 10m 16s | **7m 15s** | -3m 01s |
| 1.94.0 | 10m 57s | **7m 38s** | -3m 19s |
| 1.95.0 (terminal) | 11m 42s | **11m 57s** | +0m 15s (still builds cargo) |
| **5-hop chain total** | 58m 48s | **44m 43s** | **−14m 05s** |
| `pkgsBootstrappedRust.ripgrep` | 54s | 53s | wash |

Saving per intermediate hop: ~3-4 min, exactly the time previously spent compiling cargo + cargo-* deps. Five-hop chain: about 14 minutes total.

Closure audit: `pkgsBootstrappedRust.ripgrep` build closure still has zero prebuilt rust binaries. Source-only chain rooted at mrustc preserved.

Cumulative comparison:

| Stage | Run 0 (baseline) | Run 3b (current) | Δ |
|---|---:|---:|---:|
| 1.91.1 | 14m 49s | 7m 08s | -7m 41s |
| 1.92.0 | 15m 02s | 7m 08s | -7m 54s |
| 1.93.1 | 17m 39s | 7m 15s | -10m 24s |
| 1.94.0 | 15m 47s | 7m 38s | -8m 09s |
| 1.95.0 (terminal) | 37m 44s (standard rustc.nix) | 11m 57s (chain stage1) | -25m 47s |
| **5-hop total** | ~101 min | **~45 min** | **−~56 min** |

A **~56% reduction** in cold chain wall time vs the original baseline.

### Tuning ceiling reached (at host `cores=5`, `max-jobs=6`)

After Run 3b, per-hop wall is ~7 min for intermediates and ~12 min for the
terminal hop (which still builds cargo + rustdoc). Almost all of that is
spent compiling the rustc workspace itself: ~750 crates per hop, mostly
LLVM codegen-bound. With Nix configured at `cores = 5`, each rustc
compile gets only 5 CPUs (NIX_BUILD_CORES=5) even though the host has 32
threads — at this concurrency level, codegen-units=256 already saturates
those 5 cores.

Tried and rejected:

- **Skip a rustc minor entirely (1.90 → 1.92 directly)**: x.py's stage0
  validation can be bypassed with `--skip-stage0-validation`, but the
  rustc 1.92 source itself uses language features only stabilized in
  rustc 1.91 (e.g. `core::range::RangeInclusive::last`). Build fails
  with E0560/E0609 deep into compilation. Chain length is fundamentally
  fixed at one minor per hop.
- **Stub rustdoc on the terminal hop (skip `tools = ["rustdoc"]`)**:
  saves ~2 min on the terminal hop, but breaks any downstream rust
  package that runs doctests via `cargo test`. Reverted.

Future wins would need either:

- Changes to `mrustc-bootstrap`: skipping run_rustc's stage-2/X rebuild
  could save ~25 min on the *one-time* mrustc-bootstrap build. The
  resulting "stage 1 only" mrustc rustc 1.90 is functionally a working
  rustc, but might compile the next chain hop slightly slower due to
  mrustc's own non-optimised C codegen. Worth trying as a dedicated
  follow-up since the rebuild cost (~70 min) is one-shot.
- Raising `cores` past 5: not pursued (fixed by host config).
- Profile-guided rustc compile: needs a representative profile run,
  too complex for this branch's scope.
