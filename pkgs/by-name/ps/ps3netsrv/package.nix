{
  lib,
  stdenv,
  fetchzip,
  mbedtls,
  meson,
  ninja,
}:
let
  webManModVersion = "1.47.42";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "ps3netsrv";
  version = "20220813";

  src = fetchzip {
    url = "https://github.com/aldostools/webMAN-MOD/releases/download/${webManModVersion}/ps3netsrv_${finalAttrs.version}.zip";
    hash = "sha256-ynFuCD+tp8E/DDdB/HU9BCmwKcmQy6NBx26MKnP4W0o=";
  };

  sourceRoot = "${finalAttrs.src.name}/ps3netsrv";

  buildInputs = [
    meson
    ninja
    mbedtls
  ];

  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.isDarwin "-Doff64_t=off_t";

  postInstall = ''
    install -Dm644 ../LICENSE.TXT $out/usr/share/licenses/ps3netsrv/LICENSE.TXT
  '';

  meta = {
    description = "PS3 Net Server (mod by aldostools)";
    homepage = "https://github.com/aldostools/webMAN-MOD/";
    license = lib.licenses.gpl3;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ makefu ];
    mainProgram = "ps3netsrv";
  };
})
