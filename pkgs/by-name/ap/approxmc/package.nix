{
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  zlib,
  gmp,
  mpfr,
  cryptominisat,
  arjun-cnf,
  lib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "approxmc";
  version = "4.3.2";

  src = fetchFromGitHub {
    owner = "meelgroup";
    repo = "approxmc";
    rev = "release/v${finalAttrs.version}";
    hash = "sha256-cemZVrBQ92uQ1LBdKpJlSgEkjc8tfgMoT9gqKP2GDqQ=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    zlib
    gmp
    mpfr
    cryptominisat
    arjun-cnf
  ];

  cmakeFlags = [
    "-Dcadical_DIR=${cryptominisat}/lib/cmake/cadical"
    "-Dcadiback_DIR=${cryptominisat}/lib/cmake/cadiback"
    "-Dcryptominisat5_DIR=${cryptominisat}/lib/cmake/cryptominisat5"
    "-Darjun_DIR=${arjun-cnf}/lib/cmake/arjun"
  ];

  meta = {
    description = "Approximate Model Counter";
    homepage = "https://github.com/meelgroup/approxmc";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ t4ccer ];
    platforms = lib.platforms.linux;
    mainProgram = "approxmc";
  };
})
