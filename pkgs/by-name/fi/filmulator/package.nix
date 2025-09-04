{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt5,
  curl,
  exiv2,
  libarchive,
  libraw,
  librtprocess,
  libtiff,
  lensfun,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "filmulator";
  version = "0.11.1";

  src = fetchFromGitHub {
    owner = "CarVac";
    repo = "filmulator-gui";
    rev = "v${finalAttrs.version}";
    hash = "sha256-d1JVfPFzWsjHH9QVOyBg6wxjd5FZfRpR5/qivrk4eJM=";
  };

  sourceRoot = "${finalAttrs.src.name}/filmulator-gui";

  nativeBuildInputs = [
    cmake
    pkg-config
    qt5.qttools
    qt5.wrapQtAppsHook
  ];

  buildInputs =
    [
      curl
      exiv2
      libarchive
      libraw
      librtprocess
      libtiff
      qt5.qtbase
      qt5.qtquickcontrols2
      # Use latest lensfun git version as recommended for Linux in Filmulator README
      (lensfun.overrideAttrs (old: {
        version = "0.3.95-git-unstable-2023-05-27";
        src = fetchFromGitHub {
          owner = "lensfun";
          repo = "lensfun";
          rev = "a1510e6f33ce9bc8b5056a823c6d5bc6b8cba033";
          hash = "sha256-qdONyKk873Tq11M33JmznhJMAGd4dqp5KdXdVhfy/Ak=";
        };
      }))
    ]
    ++ lib.optionals stdenv.cc.isGNU [
      stdenv.cc.cc.lib
    ];

  cmakeFlags = [
    (lib.cmakeFeature "QT_VERSION_MAJOR" "5")
  ];

  postPatch = ''
    # Fix Exiv2 API compatibility
    substituteInPlace core/imwriteJpeg.cpp \
      --replace-quiet "Exiv2::AnyError" "Exiv2::Error"

    substituteInPlace database/exifFunctions.cpp \
      --replace-quiet ".toLong()" ".toInt64()"
  '';

  meta = {
    description = "Simplified raw editing with the power of film";
    longDescription = ''
      Filmulator is a raw photo editor that simulates the development of film as if
      exposed to the same light as the camera's sensor. This brings about several
      benefits: large bright regions become darker, small bright regions make their
      surroundings darker, saturation is enhanced in bright regions, and in extremely
      saturated regions the brightness is attenuated to help retain detail.
    '';
    homepage = "https://filmulator.org";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ siraben ];
    mainProgram = "filmulator-gui";
    platforms = lib.platforms.linux;
  };
})
