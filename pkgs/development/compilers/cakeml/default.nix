{ lib, stdenv, fetchFromGitHub, polyml, hol }:

let
  holSrc = fetchFromGitHub {
    owner = "HOL-Theorem-Prover";
    repo = "HOL";
    rev = "f55fd784a053e1236fc0d9efd5bcd7a113448971";
    sha256 = "sha256-AZoiYrnBkicw2Ut2EExTLlB+iQV0WIg1nVaHL3KLRYw=";
  };
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

  nativeBuildInputs = [ polyml hol ];

  buildPhase = ''
    cp -a ${holSrc} .
    HOLDIR=$(pwd)
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
