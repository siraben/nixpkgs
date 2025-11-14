{
  lib,
  fetchgit,
  gmp,
  mltonBootstrap,
  url ? "https://github.com/mlton/mlton",
  rev,
  sha256,
  stdenv,
  version,
  which,
}:

stdenv.mkDerivation {
  pname = "mlton";
  inherit version;

  src = fetchgit {
    inherit url rev sha256;
  };

  nativeBuildInputs = [
    which
    mltonBootstrap
  ];

  buildInputs = [ gmp ];

  strictDeps = true;

  # build fails otherwise
  enableParallelBuilding = false;

  preBuild = ''
    find . -type f | grep -v -e '\.tgz''$' | xargs sed -i "s@/usr/bin/env bash@$(type -p bash)@"
    sed -i "s|/tmp|$TMPDIR|" bin/regression

    ${lib.optionalString (stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64) ''
      # Bootstrap mlton for aarch64-darwin was built on macOS 12, so we need to match
      export MACOSX_DEPLOYMENT_TARGET=12.0
    ''}

    makeFlagsArray=(
      MLTON_VERSION="${version} ${rev}"
      CC="$(type -p cc)"
      PREFIX="$out"
      WITH_GMP_INC_DIR="${gmp.dev}/include"
      WITH_GMP_LIB_DIR="${gmp}/lib"
      )
  '';

  #  Tests fail on aarch64-darwin due to PIE/ASLR issues
  # See: https://github.com/MLton/mlton/issues/469
  doCheck = !stdenv.hostPlatform.isDarwin || !stdenv.hostPlatform.isAarch64;

  meta = import ./meta.nix { inherit lib; };
}
