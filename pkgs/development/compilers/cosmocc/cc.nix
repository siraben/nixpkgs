{
  lib,
  stdenv,
  runCommand,
  cosmocc,
  makeWrapper,
  cosmoArch ? "x86_64",
}:

let
  common = import ./cc-common.nix { inherit lib stdenv; };
  inherit (common) targetPrefix;
in
runCommand "cosmocc-cc-${cosmoArch}-${cosmocc.version}"
  {
    pname = "cosmocc-cc";
    inherit (cosmocc) version;

    nativeBuildInputs = [ makeWrapper ];

    passthru = common.passthru // {
      inherit targetPrefix;
    };

    meta = cosmocc.meta // {
      description = "Cosmopolitan C/C++ compiler for ${cosmoArch} (cc-wrapper compatible)";
    };
  }
  # Use the single-arch cross compiler rather than cosmocc (fat compiler)
  # which requires both x86_64 and aarch64 objects.
  # cosmocross is a shell script using BIN=${0%/*} so we need makeWrapper.
  ''
    mkdir -p $out/bin
    # Prefix PATH so GCC's collect2 finds cosmocc's ld.bfd instead of
    # the native linker from the nix build environment.
    makeWrapper "${cosmocc}/bin/${cosmoArch}-unknown-cosmo-cc" "$out/bin/cosmocross-cc" \
      --prefix PATH : "${cosmocc}/bin" \
      --set COMPILER_PATH "${cosmocc}/bin"
    makeWrapper "${cosmocc}/bin/${cosmoArch}-unknown-cosmo-c++" "$out/bin/cosmocross-c++" \
      --prefix PATH : "${cosmocc}/bin" \
      --set COMPILER_PATH "${cosmocc}/bin"
    ln -s $out/bin/cosmocross-cc $out/bin/${targetPrefix}gcc
    ln -s $out/bin/cosmocross-cc $out/bin/${targetPrefix}cc
    ln -s $out/bin/cosmocross-c++ $out/bin/${targetPrefix}g++
    ln -s $out/bin/cosmocross-c++ $out/bin/${targetPrefix}c++
  ''
