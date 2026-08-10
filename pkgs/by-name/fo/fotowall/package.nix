{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  qt6,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "fotowall";
  version = "1.1.3";
  strictDeps = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "fotowall";
    repo = "fotowall";
    rev = "v${finalAttrs.version}";
    hash = "sha256-u3EV8UzfESbhaIDLYimYnjDXiP0j04VKoqqO/NglFLA=";
  };

  nativeBuildInputs = [
    cmake
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtsvg
  ];

  meta = {
    description = "Pictures collage & creativity tool";
    homepage = "https://github.com/fotowall/fotowall";
    license = lib.licenses.gpl2Plus;
    maintainers = [ ];
    platforms = lib.platforms.linux;
    mainProgram = "fotowall";
  };
})
