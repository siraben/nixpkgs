{
  stdenv,
  lib,
  fetchFromGitHub,
  gnat,
  # use gprbuild-boot since gprbuild proper depends
  # on this xmlada derivation.
  gprbuild-boot,
}:

stdenv.mkDerivation rec {
  pname = "xmlada";
  version = "26.0.0";

  src = fetchFromGitHub {
    name = "xmlada-${version}-src";
    owner = "AdaCore";
    repo = "xmlada";
    rev = "v${version}";
    sha256 = "sha256-+7SaLykENypvpx/C5a93DBjusltFNEsVH1pTkfsKwPU=";
  };

  nativeBuildInputs = [
    gnat
    gprbuild-boot
  ];

  meta = {
    description = "XML/Ada: An XML parser for Ada";
    homepage = "https://github.com/AdaCore/xmlada";
    maintainers = [ lib.maintainers.sternenseemann ];
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.all;
  };
}
