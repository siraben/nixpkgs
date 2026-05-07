# Source-bootstrapped rustc chain.
#
# Each step builds a stage1 rustc + cargo + libstd from source, using
# the previous step as stage0. The chain begins with mrustc-bootstrap
# (rustc 1.90.0 from C++ via mrustc) and ends at rustc 1.94.0, which is
# then used as the bootstrap for the standard nixpkgs `rustc-unwrapped`
# (currently rustc 1.95.0).
#
# Modeled on
# https://codeberg.org/whispers/nebula/src/branch/meow/nix/pkgs/rust-bootstrap
{
  lib,
  callPackage,
  fetchurl,
  mrustc-bootstrap,
  llvmPackages_21,
}:
let
  llvmShared = llvmPackages_21.libllvm.override { enableSharedLibraries = true; };

  mkIntermediate =
    prev:
    { version, hash }:
    callPackage
      (import ./intermediate.nix {
        inherit version;
        src = fetchurl {
          url = "https://static.rust-lang.org/dist/rustc-${version}-src.tar.gz";
          inherit hash;
        };
      })
      {
        cargo = prev;
        rustc = prev;
        llvmSharedForBuild = llvmShared;
        llvmSharedForHost = llvmShared;
        llvmSharedForTarget = llvmShared;
      };

  hops = [
    {
      attr = "rustc-1_91";
      version = "1.91.1";
      hash = "sha256-ONziBdOfYVcSYfBEQjehzp7+y5cOdg2OxNlXr1tEVyM=";
    }
    {
      attr = "rustc-1_92";
      version = "1.92.0";
      hash = "sha256-ng0sp1x+J1/cdYJVv0sDr7PWXRVDYCdGkHyTO2kBw7g=";
    }
    {
      attr = "rustc-1_93";
      version = "1.93.1";
      hash = "sha256-TCMKRLPZyfPO+VCUNxn4OABY0nyR/aXjapqUfvAT4B8=";
    }
    {
      attr = "rustc-1_94";
      version = "1.94.0";
      hash = "sha256-uD+SHNPzIf9hT5wGqLhw2JKZ/AKIi0ilVJaDo2gjR0w=";
    }
  ];
in
(lib.foldl'
  (
    state: hop:
    let
      drv = mkIntermediate state.prev { inherit (hop) version hash; };
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
