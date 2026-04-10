{
  lib,
  stdenv,
  runCommand,
  cosmocc,
  makeWrapper,
}:

let
  common = import ./cc-common.nix { inherit lib stdenv; };
  inherit (common) targetPrefix;

in
runCommand "cosmocc-cc-fat-${cosmocc.version}"
  {
    pname = "cosmocc-cc-fat";
    inherit (cosmocc) version;

    nativeBuildInputs = [ makeWrapper ];

    passthru = common.passthru // {
      inherit targetPrefix;
    };

    meta = cosmocc.meta // {
      description = "Cosmopolitan fat C/C++ compiler (x86_64 + aarch64)";
    };
  }
  # Use cosmocc/cosmoc++ (fat compiler) which compiles for both x86_64
  # and aarch64, producing Actually Portable Executables.
  # These are shell scripts using BIN=${0%/*} so we need makeWrapper.
  ''
    mkdir -p $out/bin
    makeWrapper "${cosmocc}/bin/cosmocc" "$out/bin/cosmocc" \
      --set COMPILER_PATH "${cosmocc}/bin"
    makeWrapper "${cosmocc}/bin/cosmoc++" "$out/bin/cosmoc++" \
      --set COMPILER_PATH "${cosmocc}/bin"
    ln -s $out/bin/cosmocc $out/bin/${targetPrefix}gcc
    ln -s $out/bin/cosmocc $out/bin/${targetPrefix}cc
    ln -s $out/bin/cosmoc++ $out/bin/${targetPrefix}g++
    ln -s $out/bin/cosmoc++ $out/bin/${targetPrefix}c++
  ''
