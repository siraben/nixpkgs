{
  stdenv,
  fetchFromGitHub,
  writeText,
  cmake,
  pkg-config,
  cryptominisat,
  gmp,
  mpfr,
  zlib,
  lib,
}:

let
  sbvaSrc = fetchFromGitHub {
    owner = "meelgroup";
    repo = "sbva";
    rev = "f1021c17dddee4fcd5d552969f459482907f9f84";
    hash = "sha256-7TchTyfk77lZgEfExy3LIv5DdtUkXh0oN1y9lzfhKQw=";
  };
  dependencySetup = writeText "arjun-dependency-setup.cmake" ''
    find_package(cadical CONFIG REQUIRED
      PATHS "${cryptominisat}/lib/cmake/cadical"
      NO_DEFAULT_PATH)
  '';
in
stdenv.mkDerivation (finalAttrs: {
  pname = "arjun-cnf";
  version = "2.7.3";

  src = fetchFromGitHub {
    owner = "meelgroup";
    repo = "arjun";
    rev = "release/v${finalAttrs.version}";
    hash = "sha256-gbzfA2nm20Qx0wunXBFxyyXI3Wbgs+PmU2u3WhAusDQ=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cryptominisat
    gmp
    mpfr
    zlib
  ];

  postPatch = ''
    substituteInPlace arjunConfig.cmake.in \
      --replace-fail "find_dependency(treedecomp REQUIRED CONFIG)" ""
  '';

  cmakeFlags = [
    "-DCMAKE_PROJECT_INCLUDE=${dependencySetup}"
    "-Dcadical_DIR=${cryptominisat}/lib/cmake/cadical"
    "-Dcadiback_DIR=${cryptominisat}/lib/cmake/cadiback"
    "-Dcryptominisat5_DIR=${cryptominisat}/lib/cmake/cryptominisat5"
    "-DFETCHCONTENT_SOURCE_DIR_SBVA=${sbvaSrc}"
  ];

  meta = {
    description = "CNF minimizer and minimal independent set calculator";
    homepage = "https://github.com/meelgroup/arjun";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ t4ccer ];
    platforms = lib.platforms.linux;
    mainProgram = "arjun";
  };
})
