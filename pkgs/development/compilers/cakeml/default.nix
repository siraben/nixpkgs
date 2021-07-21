{ lib, stdenv, fetchFromGitHub, polyml, hol }:

let
  holSrc = fetchFromGitHub {
    owner = "HOL-Theorem-Prover";
    repo = "HOL";
    rev = "fe4634b86ea93f927bb796c73b7f77e15362962e";
    sha256 = "sha256-YEhSEHzNh376YdiJDhIbiMH51fGSiG6RwhtFiu+sIQ0=";
  };
  hol' = hol.overrideDerivation (self: { src = holSrc; });
in

stdenv.mkDerivation rec {
  pname = "cakeml";
  version = "v1535";

  src = fetchFromGitHub {
    owner = "CakeML";
    repo = "cakeml";
    rev = version;
    sha256 = "sha256-E2E8fwIYD53H1MFzrHSH8gpAP8NCzTOM/d9HlPJdGAU=";
  };

  nativeBuildInputs = [ polyml hol' ];

  buildPhase = ''
    Holmake
  '';

  meta = with lib; {
    description = "CakeML: A Verified Implementation of ML";
    homepage = "https://github.com/CakeML/cakeml";
    license = licenses.mit;
    maintainers = with maintainers; [ siraben ];
    platforms = platforms.unix;
  };
}
