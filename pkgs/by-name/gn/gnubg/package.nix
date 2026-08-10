{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  flex,
  glib,
  python3,
  gtk2,
  readline,
  copyDesktopItems,
  makeDesktopItem,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gnubg";
  version = "1.08.003";

  src = fetchurl {
    url = "mirror://gnu/gnubg/gnubg-release-${finalAttrs.version}-sources.tar.gz";
    hash = "sha256-b32WmxPP/3hvupD/jMXl1WS5f08Kppr+Tzg48YxEWXk=";
  };

  nativeBuildInputs = [
    copyDesktopItems
    pkg-config
    python3
    flex
    glib
  ];

  buildInputs = [
    gtk2
    readline
  ];

  strictDeps = true;

  configureFlags = [
    "--with-gtk"
    "--with--board3d"
  ];

  desktopItems = [
    (makeDesktopItem {
      desktopName = "GNU Backgammon";
      name = "gnubg";
      genericName = "Backgammon";
      comment = finalAttrs.meta.description;
      exec = "gnubg";
      icon = "gnubg";
      categories = [
        "Game"
        "GTK"
        "StrategyGame"
      ];
    })
  ];

  meta = {
    description = "World class backgammon application";
    homepage = "https://www.gnu.org/software/gnubg/";
    license = lib.licenses.gpl3;
    platforms = lib.platforms.linux;
  };
})
