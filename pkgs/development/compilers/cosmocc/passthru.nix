{
  stdenv,
  cosmocc,
  callPackage,
  wrapCCWith,
  wrapBintoolsWith,
  overrideCC,
}:

let
  cosmoWrapBintools =
    bintools-unwrapped:
    (wrapBintoolsWith {
      bintools = bintools-unwrapped;
      libc = null;
    }).overrideAttrs
      (old: {
        # Add unprefixed ld/ld.bfd so GCC's collect2 (which searches for
        # just "ld.bfd" via -fuse-ld=bfd) finds cosmocc's linker instead
        # of the native one from the build environment.
        postFixup = (old.postFixup or "") + ''
          ln -sf ${bintools-unwrapped}/bin/ld $out/bin/ld
          ln -sf ${bintools-unwrapped}/bin/ld.bfd $out/bin/ld.bfd
        '';
      });

  cosmoWrapCC =
    { cc-unwrapped, bintools }:
    wrapCCWith {
      cc = cc-unwrapped;
      inherit bintools;
      libc = null;
      extraPackages = [ ];
      useCcForLibs = false;
      gccForLibs = null;
      # Clear the -B/-L flags that cc-wrapper adds by default (pointing
      # at cc_solib/lib which doesn't exist for cosmocc).
      extraBuildCommands = ''
        : > $out/nix-support/cc-cflags
        : > $out/nix-support/cc-ldflags
      '';
    };

  mkCosmoToolchain =
    cosmoArch:
    let
      bintools-unwrapped = callPackage ./bintools.nix { inherit cosmocc cosmoArch; };
      bintools = cosmoWrapBintools bintools-unwrapped;
      cc-unwrapped = callPackage ./cc.nix { inherit cosmocc cosmoArch; };
      cc = cosmoWrapCC { inherit cc-unwrapped bintools; };
    in
    {
      inherit bintools-unwrapped bintools cc-unwrapped cc;
    };

  x86_64 = mkCosmoToolchain "x86_64";
  aarch64 = mkCosmoToolchain "aarch64";

  fat =
    let
      bintools-unwrapped = callPackage ./bintools-fat.nix { inherit cosmocc; };
      bintools = cosmoWrapBintools bintools-unwrapped;
      cc-unwrapped = callPackage ./cc-fat.nix { inherit cosmocc; };
      cc = cosmoWrapCC { inherit cc-unwrapped bintools; };
    in
    {
      inherit bintools-unwrapped bintools cc-unwrapped cc;
      stdenv = overrideCC stdenv cc;
    };
in
{
  # Default (x86_64) toolchain
  inherit (x86_64) bintools-unwrapped bintools cc-unwrapped cc;
  stdenv = overrideCC stdenv x86_64.cc;

  # Architecture-specific toolchains
  aarch64 = {
    inherit (aarch64) bintools-unwrapped bintools cc-unwrapped cc;
    stdenv = overrideCC stdenv aarch64.cc;
  };

  # Fat toolchain (x86_64 + aarch64)
  inherit fat;
}
