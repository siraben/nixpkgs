{
  lib,
  stdenv,
  fetchFromGitHub,
  zlib,
}:

let
  # mrustc HEAD post-2026-04-13 is the first version that bootstraps
  # rustc 1.90.0 (binary-equal to upstream rustc 1.91.1). No tagged
  # release has this capability yet; pin a specific commit until v0.13.
  version = "0.12.0-unstable-2026-04-13";
  rev = "7392eca5bd4958cb184fb47cefbd4c7e4f43547b";
  shortRev = builtins.substring 0 7 rev;
  tag = rev;
in

stdenv.mkDerivation rec {
  pname = "mrustc";
  inherit version;

  # Always update minicargo.nix and bootstrap.nix in lockstep with this
  src = fetchFromGitHub {
    owner = "thepowersgang";
    repo = "mrustc";
    inherit rev;
    hash = "sha256-dn17f2fPvfGqGlveHk/7f5hk/jSTd8XOdPb1pPeTHJ8=";
  };

  postPatch = ''
    substituteInPlace Makefile \
      --replace-fail '$(shell git show --pretty=%H -s --no-show-signature)' '${rev}' \
      --replace-fail '$(shell git show -s --pretty=%h --no-show-signature)' '${shortRev}' \
      --replace-fail '$(shell git symbolic-ref -q --short HEAD || git describe --tags --exact-match)' '${tag}' \
      --replace-fail '$(shell git diff-index --quiet HEAD; echo $$?)' '0' \
      --replace-fail '$(shell env LC_TIME=C date -u +"%a, %e %b %Y %T +0000")' 'unknown'

    if ! grep -q '#include <limits>' src/trans/codegen_c.cpp; then
      sed '1i#include <limits>' -i src/trans/codegen_c.cpp
    fi
  '';

  strictDeps = true;
  buildInputs = [ zlib ];
  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp bin/mrustc $out/bin
    runHook postInstall
  '';

  meta = {
    description = "Mutabah's Rust Compiler";
    mainProgram = "mrustc";
    longDescription = ''
      In-progress alternative rust compiler, written in C++.
      Capable of building a fully-working copy of rustc,
      but not yet suitable for everyday use.
    '';
    inherit (src.meta) homepage;
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      progval
      r-burns
    ];
    platforms = [ "x86_64-linux" ];
  };
}
