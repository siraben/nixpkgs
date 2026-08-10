{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "tclap";
  version = "1.2.5";

  src = fetchurl {
    url = "mirror://sourceforge/tclap/tclap-${finalAttrs.version}.tar.gz";
    sha256 = "sha256-u2SfdtrjXo0Ny6S1Ks/U4GLXh+aoG0P3pLASdRUxZaY=";
  };

  meta = {
    homepage = "https://tclap.sourceforge.net/";
    description = "Templatized C++ Command Line Parser Library";
    platforms = lib.platforms.all;
    license = lib.licenses.mit;
  };
})
