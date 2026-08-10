{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mpv-shim-default-shaders";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "iwalton3";
    repo = "default-shader-pack";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-BM2GvmUoWQUUMH464YIIqu5A1t1B+otbJxAGFbySuq8=";
  };

  installPhase = ''
    mkdir -p $out/share/mpv-shim-default-shaders
    cp -r shaders *.json $out/share/mpv-shim-default-shaders
  '';

  meta = {
    homepage = "https://github.com/iwalton3/default-shader-pack";
    description = "Preconfigured set of MPV shaders and configurations for MPV Shim media clients";
    license = with lib.licenses; [
      gpl3Plus
      mit
      unlicense
    ];
    maintainers = with lib.maintainers; [ devusb ];
  };
})
