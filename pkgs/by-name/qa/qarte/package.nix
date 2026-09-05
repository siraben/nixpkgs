{
  lib,
  stdenv,
  fetchurl,
  ffmpeg-headless,
  libsForQt5,
  python3,
}:

let
  pythonEnv = python3.withPackages (
    ps: with ps; [
      m3u8
      pyqt5-multimedia
    ]
  );
in
stdenv.mkDerivation rec {
  pname = "qarte";
  version = "5.18.0";

  src = fetchurl {
    url = "https://launchpad.net/~vincent-vandevyvre/+archive/ubuntu/vvv/+sourcefiles/qarte/${version}-0ubuntu1/qarte_${version}.orig.tar.gz";
    hash = "sha256-PLLyMxuyzODqLHkT0tJ0tErYE+ZcWK8jQwpywcVBjlQ=";
  };

  nativeBuildInputs = [ libsForQt5.wrapQtAppsHook ];

  buildInputs = [ pythonEnv ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mv qarte $out/bin/
    substituteInPlace $out/bin/qarte \
      --replace-fail '/usr/share' "$out/share"

    mkdir -p $out/share/{applications,man/man1,pixmaps,qarte}
    mv qarte.1 $out/share/man/man1/
    mv q_arte.desktop $out/share/applications/
    mv qarte.png $out/share/pixmaps/
    mv locale $out/share/

    substituteInPlace core.py \
      --replace-fail "'/usr/share/locale'" "'$out/share/locale'"
    mv * $out/share/qarte/

    runHook postInstall
  '';

  postFixup = ''
    wrapQtApp $out/bin/qarte \
      --prefix PATH : ${ffmpeg-headless}/bin
  '';

  meta = {
    homepage = "https://launchpad.net/qarte";
    description = "Recorder for Arte TV Guide and Arte Concert";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ vbgl ];
    platforms = lib.platforms.linux;
    mainProgram = "qarte";
  };
}
