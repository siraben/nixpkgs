# Source-bootstrapped rustc chain. Each hop builds a stage1 rustc + libstd
# from source, using the previous hop as stage0. Modeled on
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
  # Move libLLVM*.a out of $lib so consumers of libLLVM.so don't drag the
  # ~370 MB static-archive pile into their runtime closure. Chain-local;
  # pkgs.llvmPackages_* is unchanged.
  mkLlvmShared =
    llvmPackages:
    (llvmPackages.libllvm.override { enableSharedLibraries = true; }).overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        find $lib/lib -maxdepth 1 -name '*.a' -exec mv -t $dev/lib/ {} +
      '';
    });
  llvmShared_21 = mkLlvmShared llvmPackages_21;
  llvmShared_22 = mkLlvmShared llvmPackages_22;

  # `llvmShared` defaults to `llvmShared_21`; rustc 1.95 needs LLVM 22 (see
  # the `src/llvm-project` submodule of each release).
  hops = [
    { version = "1.91.1"; hash = "sha256-ONziBdOfYVcSYfBEQjehzp7+y5cOdg2OxNlXr1tEVyM="; }
    { version = "1.92.0"; hash = "sha256-ng0sp1x+J1/cdYJVv0sDr7PWXRVDYCdGkHyTO2kBw7g="; }
    { version = "1.93.1"; hash = "sha256-TCMKRLPZyfPO+VCUNxn4OABY0nyR/aXjapqUfvAT4B8="; }
    { version = "1.94.0"; hash = "sha256-uD+SHNPzIf9hT5wGqLhw2JKZ/AKIi0ilVJaDo2gjR0w="; }
    {
      # Terminal hop: feeds pkgs.rustc and pkgs.cargo via wrapRustcWith /
      # the pkgsBootstrappedRust overlay.
      version = "1.95.0";
      hash = "sha256-6puCqD5GlnU3w1ac6db6FoEcBDqW5lE3bDSecCQcpRU=";
      llvmShared = llvmShared_22;
      tools = [
        "cargo"
        "rustdoc"
      ];
    }
  ];

  # cargo 1.90 from mrustc-bootstrap drives every hop via
  # --skip-stage0-validation, so intermediate hops skip building cargo.
  mkHop =
    rustc: hop:
    callPackage
      (import ./intermediate.nix {
        inherit (hop) version;
        tools = hop.tools or [ ];
        src = fetchurl {
          url = "https://static.rust-lang.org/dist/rustc-${hop.version}-src.tar.gz";
          inherit (hop) hash;
        };
      })
      {
        inherit rustc;
        llvmShared = hop.llvmShared or llvmShared_21;
        cargo = mrustc-bootstrap;
      };

  attrName = v: "rustc-${lib.replaceStrings [ "." ] [ "_" ] (lib.versions.majorMinor v)}";

  step =
    state: hop:
    let
      drv = mkHop state.prev hop;
    in
    {
      attrs = state.attrs // { ${attrName hop.version} = drv; };
      prev = drv;
    };
in
(lib.foldl' step {
  attrs = { };
  prev = mrustc-bootstrap;
} hops).attrs
