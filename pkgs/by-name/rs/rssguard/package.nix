{
  lib,
  stdenv,
  fetchurl,
  go,
  cmake,
  qt6,
  mpv-unwrapped,
  wrapGAppsHook4,
}:

let
  version = "5.2.5";
  src = fetchurl {
    url = "https://github.com/martinrotter/rssguard/releases/download/${version}/rssguard-${version}-src.tar.gz";
    hash = "sha256-UFEwiq/4VOWxlI4jsChxzY1PtLhwvbaIqLmOkH5qBhQ=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "rssguard";
  inherit version src;

  buildInputs = [
    qt6.qtbase
    qt6.qtmultimedia
    qt6.qtwebengine
    qt6.qttools
    mpv-unwrapped
  ];
  nativeBuildInputs = [
    cmake
    go
    wrapGAppsHook4
    qt6.wrapQtAppsHook
  ];

  cmakeFlags = [ (lib.cmakeBool "ENABLE_TESTING" true) ];

  preConfigure = ''
    export GOCACHE=$TMPDIR/go-cache
    export GOPATH=$TMPDIR/go
    export GOPROXY=off
  '';

  doCheck = true;

  dontWrapGApps = true;

  preFixup = ''
    qtWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';

  meta = {
    description = "Simple RSS/Atom feed reader with online synchronization";
    mainProgram = "rssguard";
    longDescription = ''
      RSS Guard is a simple, light and easy-to-use RSS/ATOM feed aggregator
      developed using Qt framework and with online feed synchronization support
      for ownCloud/Nextcloud.
    '';
    homepage = "https://github.com/martinrotter/rssguard";
    changelog = "https://github.com/martinrotter/rssguard/releases/tag/${finalAttrs.version}";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [
      jluttine
      tebriel
    ];
  };
})
