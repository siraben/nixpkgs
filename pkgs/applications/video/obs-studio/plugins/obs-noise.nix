{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  obs-studio,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "obs-noise";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "FiniteSingularity";
    repo = "obs-noise";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-D9vGXCrmQ8IDRmL8qZ1ZBiOz9AjhKm45W37zC16kRCk=";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ obs-studio ];

  postFixup = ''
    mv $out/data/obs-plugins/obs-noise/shaders $out/share/obs/obs-plugins/obs-noise/
    rm -rf $out/data $out/obs-plugins
  '';

  meta = {
    description = "Plug-in for noise generation and noise effects for OBS";
    homepage = "https://github.com/FiniteSingularity/obs-noise";
    maintainers = with lib.maintainers; [ flexiondotorg ];
    license = lib.licenses.gpl2Only;
    inherit (obs-studio.meta) platforms;
  };
})
