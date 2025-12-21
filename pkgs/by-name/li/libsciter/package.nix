{
  lib,
  glib,
  cairo,
  libuuid,
  pango,
  gtk3,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

let
  inherit (stdenv.targetPlatform) system;

  src.x86_64-linux = {
    urlPath = "x64";
    fileName = "libsciter-gtk.so";
    sha256 = "a1682fbf55e004f1862d6ace31b5220121d20906bdbf308d0a9237b451e4db86";
  };

  src.aarch64-linux = {
    urlPath = "arm64";
    fileName = "libsciter-gtk.so";
    sha256 = "sha256-bqGPbvtOM8/A6acDbFJGGf4kzKo/4S/bWcH/XvxVySU=";
  };

  src.x86_64-darwin = {
    urlPath = "";
    fileName = "libsciter.dylib";
    sha256 = "sha256-qNhEQ5tDy3DwKoYQxzX/3nikG6oeVRBYuGkURjAkCg0=";
  };

  src.aarch64-darwin = {
    urlPath = "";
    fileName = "libsciter.dylib";
    sha256 = "sha256-qNhEQ5tDy3DwKoYQxzX/3nikG6oeVRBYuGkURjAkCg0=";  # Same universal binary
  };

in

stdenv.mkDerivation {
  pname = "libsciter";
  version = "4.4.8.23-bis"; # Version specified in GitHub commit title

  src = fetchurl {
    url = if stdenv.hostPlatform.isLinux then
      "https://github.com/c-smile/sciter-sdk/raw/524a90ef7eab16575df9496f7e4c374bbd5fb1fe/bin.lnx/${src.${system}.urlPath}/${src.${system}.fileName}"
    else
      "https://raw.githubusercontent.com/c-smile/sciter-sdk/master/bin.osx/${src.${system}.fileName}";
    inherit (src.${system}) sha256;
  };

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    glib
    cairo
    libuuid
    pango
    gtk3
  ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -m755 -D $src $out/lib/${src.${system}.fileName}

    runHook postInstall
  '';

  meta = {
    homepage = "https://sciter.com";
    description = "Embeddable HTML/CSS/JavaScript engine for modern UI development";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    maintainers = with lib.maintainers; [ leixb ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
  };
}
