{
  lib,
  stdenv,
  fetchFromGitLab,
  rustPlatform,
  meson,
  ninja,
  pkg-config,
  rustc,
  cargo,
  wrapGAppsHook4,
  desktop-file-utils,
  libxml2,
  libadwaita,
  openssl,
  libsoup_3,
  webkitgtk_6_0,
  sqlite,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "read-it-later";
  version = "0.6.3";

  src = fetchFromGitLab {
    domain = "gitlab.gnome.org";
    owner = "World";
    repo = "read-it-later";
    tag = finalAttrs.version;
    hash = "sha256-m4s5oW8JlRogPVriJ+WHhEmf1asmZoC8f5zgPW0Crpc=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    pname = "read-it-later";
    inherit (finalAttrs) version;
    inherit (finalAttrs) src;
    hash = "sha256-hAdWDzEs1Xs5Ywa7uxCvB8E9NqKVWbMtJSjoCeXHklM=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    rustPlatform.cargoSetupHook
    rustc
    cargo
    wrapGAppsHook4
    desktop-file-utils
    libxml2.bin # xmllint
  ];

  buildInputs = [
    libadwaita
    openssl
    libsoup_3
    webkitgtk_6_0
    sqlite
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Simple Wallabag client with basic features to manage articles";
    homepage = "https://gitlab.gnome.org/World/read-it-later";
    changelog = "https://gitlab.gnome.org/World/read-it-later/-/releases/${finalAttrs.src.tag}";
    license = lib.licenses.gpl3Plus;
    mainProgram = "read-it-later";
    maintainers = with lib.maintainers; [ aleksana ];
    platforms = lib.platforms.unix;
  };
})
