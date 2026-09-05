{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  gmp,
  zlib,
}:

let
  cadicalSrc = fetchFromGitHub {
    owner = "meelgroup";
    repo = "cadical";
    rev = "394c3f72858c2fe8cd35321f74f11f0f61c91123";
    hash = "sha256-vOkBGnRWR1lT0Ik1WmoNjfIILM7Sk6ofSIbkiIdA68U=";
  };
  cadibackSrc = fetchFromGitHub {
    owner = "meelgroup";
    repo = "cadiback";
    rev = "3b6a84062b1304433eb8960a4bff6b9a80de9c54";
    hash = "sha256-pLGyzOpr5+j44ORtJr9GslySxHK/6n+x5lQM14JG+mE=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "cryptominisat";
  version = "5.14.7";

  src = fetchFromGitHub {
    owner = "msoos";
    repo = "cryptominisat";
    rev = "release/v${finalAttrs.version}";
    hash = "sha256-nyAoAQ5k+C1M1pK71SAA2eUnCuD0mM8ImSKNxbxRKQs=";
  };

  patches = [ ./propagate-cxx-standard.patch ];

  strictDeps = true;
  buildInputs = [ zlib ];
  propagatedBuildInputs = [ gmp ];
  nativeBuildInputs = [ cmake ];
  propagatedNativeBuildInputs = [ pkg-config ];

  cmakeFlags = [
    "-DFETCHCONTENT_SOURCE_DIR_CADICAL=${cadicalSrc}"
    "-DFETCHCONTENT_SOURCE_DIR_CADIBACK=${cadibackSrc}"
  ];

  meta = {
    description = "Advanced SAT Solver";
    mainProgram = "cryptominisat5";
    homepage = "https://github.com/msoos/cryptominisat";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ mic92 ];
    platforms = lib.platforms.unix;
  };
})
