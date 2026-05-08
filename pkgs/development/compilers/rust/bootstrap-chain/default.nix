# Source-bootstrapped rustc chain.
#
# Each hop builds a stage1 rustc + libstd from source, using the
# previous hop as stage0 rustc. cargo 1.90.0 from `mrustc-bootstrap`
# drives every hop (see `intermediate.nix` for why), so intermediate
# hops skip building cargo. The terminal hop (1.95.0) builds cargo +
# rustdoc to feed `pkgs.cargo` and `wrapRustcWith`.
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

  attrName = version: "rustc-${lib.replaceStrings [ "." ] [ "_" ] (lib.versions.majorMinor version)}";

  mkHop =
    rustc: hop:
    callPackage
      (import ./intermediate.nix {
        inherit (hop) version tools;
        src = fetchurl {
          url = "https://static.rust-lang.org/dist/rustc-${hop.version}-src.tar.gz";
          inherit (hop) hash;
        };
      })
      {
        inherit rustc;
        inherit (hop) llvmShared;
        cargo = mrustc-bootstrap;
      };

  # Each hop's `llvmShared` matches the LLVM major upstream rustc was
  # tested against (per `.gitmodules` `src/llvm-project` branch):
  #   rustc 1.91-1.94 -> rustc/21.1-2025-08-01
  #   rustc 1.95      -> rustc/22.1-2026-01-27
  hops = [
    {
      version = "1.91.1";
      hash = "sha256-ONziBdOfYVcSYfBEQjehzp7+y5cOdg2OxNlXr1tEVyM=";
      llvmShared = llvmShared_21;
      tools = [ ];
    }
    {
      version = "1.92.0";
      hash = "sha256-ng0sp1x+J1/cdYJVv0sDr7PWXRVDYCdGkHyTO2kBw7g=";
      llvmShared = llvmShared_21;
      tools = [ ];
    }
    {
      version = "1.93.1";
      hash = "sha256-TCMKRLPZyfPO+VCUNxn4OABY0nyR/aXjapqUfvAT4B8=";
      llvmShared = llvmShared_21;
      tools = [ ];
    }
    {
      version = "1.94.0";
      hash = "sha256-uD+SHNPzIf9hT5wGqLhw2JKZ/AKIi0ilVJaDo2gjR0w=";
      llvmShared = llvmShared_21;
      tools = [ ];
    }
    {
      version = "1.95.0";
      hash = "sha256-6puCqD5GlnU3w1ac6db6FoEcBDqW5lE3bDSecCQcpRU=";
      llvmShared = llvmShared_22;
      # The terminal hop becomes `pkgs.rustc` via `wrapRustcWith` and
      # ships `pkgs.cargo` for downstream consumers.
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
      drv = mkHop state.prev hop;
    in
    {
      attrs = state.attrs // { ${attrName hop.version} = drv; };
      prev = drv;
    }
  )
  {
    attrs = { };
    prev = mrustc-bootstrap;
  }
  hops
).attrs
