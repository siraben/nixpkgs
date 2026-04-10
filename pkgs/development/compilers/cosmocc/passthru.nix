{
  lib,
  stdenv,
  runCommand,
  cosmocc,
  callPackage,
  wrapCCWith,
  wrapBintoolsWith,
  overrideCC,
}:

let
  # APE (Actually Portable Executable) loader — needed to run cosmo
  # binaries on platforms that can't execute them natively.
  #
  # The cosmocc distribution ships prebuilt loaders for three targets
  # and source (ape-m1.c) for aarch64-darwin.  Pick the right one
  # based on the host platform.
  #
  # Exposed as `cosmopolitan.cosmocc.ape-loader` so users can
  # `nix-build -A cosmopolitan.cosmocc.ape-loader` and put `ape`
  # in their PATH.
  ape-loader =
    let
      # Map host platform to the appropriate prebuilt binary or source.
      loaderSource = {
        "aarch64-darwin" = { src = "${cosmocc}/bin/ape-m1.c"; needsCompile = true; };
        "x86_64-darwin"  = { src = "${cosmocc}/bin/ape-x86_64.macho"; needsCompile = false; };
        "aarch64-linux"  = { src = "${cosmocc}/bin/ape-aarch64.elf"; needsCompile = false; };
        "x86_64-linux"   = { src = "${cosmocc}/bin/ape-x86_64.elf"; needsCompile = false; };
      }.${stdenv.hostPlatform.system}
        or (throw "cosmocc APE loader: unsupported platform ${stdenv.hostPlatform.system}");
    in
    runCommand "ape-loader-${cosmocc.version}" {
      pname = "ape-loader";
      inherit (cosmocc) version;
      nativeBuildInputs = lib.optional loaderSource.needsCompile stdenv.cc;
      meta = cosmocc.meta // {
        description = "APE loader for running Cosmopolitan binaries";
      };
    } (''
      mkdir -p $out/bin
    '' + (if loaderSource.needsCompile then ''
      cc -w -O -o $out/bin/ape ${loaderSource.src}
    '' else ''
      cp ${loaderSource.src} $out/bin/ape
      chmod +x $out/bin/ape
    ''));

  apeLoaderPath = "${ape-loader}/bin";

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
          ln -sf ${apeLoaderPath}/ape $out/bin/ape
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
        ln -sf ${apeLoaderPath}/ape $out/bin/ape
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
  # APE loader for running cosmo binaries
  inherit ape-loader;

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
