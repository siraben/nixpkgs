# Source-bootstrapped rustc chain.
#
# Each step builds a stage1 rustc + cargo + libstd from source, using
# the previous step as stage0. The chain begins with mrustc-bootstrap
# (rustc 1.90.0 from C++ via mrustc) and ends at rustc 1.95.0, all via
# the same lightweight `intermediate.nix` shape (build-stage = 1, no
# docs, `tools = ["cargo"]`).
#
# Modeled on
# https://codeberg.org/whispers/nebula/src/branch/meow/nix/pkgs/rust-bootstrap
{
  lib,
  callPackage,
  fetchurl,
  mrustc-bootstrap,
  llvmPackages_21,
  llvmPackages_22,
}:
let
  mkLlvmShared = llvmPackages: llvmPackages.libllvm.override { enableSharedLibraries = true; };
  llvmShared_21 = mkLlvmShared llvmPackages_21;
  llvmShared_22 = mkLlvmShared llvmPackages_22;

  mkIntermediate =
    prev:
    {
      version,
      hash,
      llvmShared,
      tools ? [ ],
    }:
    callPackage
      (import ./intermediate.nix {
        inherit version tools;
        src = fetchurl {
          url = "https://static.rust-lang.org/dist/rustc-${version}-src.tar.gz";
          inherit hash;
        };
      })
      {
        # Stage0 cargo is always mrustc-bootstrap's cargo 1.90.0. cargo
        # is forwards-compatible enough across stable releases that
        # cargo 1.90 can drive rustc 1.91 → 1.95 builds, which lets us
        # skip building cargo at every intermediate hop (`tools = []`).
        # Only the terminal hop builds cargo for downstream consumers.
        cargo = mrustc-bootstrap;
        rustc = prev;
        llvmSharedForBuild = llvmShared;
        llvmSharedForHost = llvmShared;
        llvmSharedForTarget = llvmShared;
      };

  # Each hop's `llvmShared` matches the LLVM major upstream rustc was
  # tested against (per `.gitmodules` `src/llvm-project` branch):
  #   rustc 1.91-1.94 -> rustc/21.1-2025-08-01
  #   rustc 1.95      -> rustc/22.1-2026-01-27
  hops = [
    {
      attr = "rustc-1_91";
      version = "1.91.1";
      hash = "sha256-ONziBdOfYVcSYfBEQjehzp7+y5cOdg2OxNlXr1tEVyM=";
      llvmShared = llvmShared_21;
    }
    {
      attr = "rustc-1_92";
      version = "1.92.0";
      hash = "sha256-ng0sp1x+J1/cdYJVv0sDr7PWXRVDYCdGkHyTO2kBw7g=";
      llvmShared = llvmShared_21;
    }
    {
      attr = "rustc-1_93";
      version = "1.93.1";
      hash = "sha256-TCMKRLPZyfPO+VCUNxn4OABY0nyR/aXjapqUfvAT4B8=";
      llvmShared = llvmShared_21;
    }
    {
      attr = "rustc-1_94";
      version = "1.94.0";
      hash = "sha256-uD+SHNPzIf9hT5wGqLhw2JKZ/AKIi0ilVJaDo2gjR0w=";
      llvmShared = llvmShared_21;
    }
    {
      attr = "rustc-1_95";
      version = "1.95.0";
      hash = "sha256-6puCqD5GlnU3w1ac6db6FoEcBDqW5lE3bDSecCQcpRU=";
      llvmShared = llvmShared_22;
      # The terminal hop becomes `pkgs.rustc` (via wrapRustcWith), which
      # symlinks rustc's `rustdoc` binary at wrapper time. Build rustdoc
      # for this hop only — intermediate hops don't need it.
      tools = [
        "cargo"
        "rustdoc"
      ];
    }
  ];
in
(lib.foldl'
  (
    state: hop:
    let
      drv = mkIntermediate state.prev (builtins.removeAttrs hop [ "attr" ]);
    in
    {
      attrs = state.attrs // { ${hop.attr} = drv; };
      prev = drv;
    }
  )
  {
    attrs = { };
    prev = mrustc-bootstrap;
  }
  hops
).attrs
