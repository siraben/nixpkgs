{
  lib,
  stdenv,
  cairo,
  cmake,
  fetchFromGitHub,
  gettext,
  gtk2-x11,
  ninja,
  pkg-config,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gerbv";
  version = "2.13.0";

  src = fetchFromGitHub {
    owner = "gerbv";
    repo = "gerbv";
    tag = "v${finalAttrs.version}";
    hash = "sha256-TByqekKlHLt9F4lQMtxmmLtlbvY2rmk2D39LZXOJpe4=";
  };

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail 'VERSION 4.0' 'VERSION ${finalAttrs.version}'
    substituteInPlace src/libgerbv.pc.in \
      --replace-fail 'libdir=@libdir@' 'libdir=@CMAKE_INSTALL_FULL_LIBDIR@' \
      --replace-fail 'includedir=@includedir@' 'includedir=@CMAKE_INSTALL_FULL_INCLUDEDIR@'
  '';

  nativeBuildInputs = [
    cmake
    gettext
    ninja
    pkg-config
  ];

  buildInputs = [
    (cairo.override { x11Support = true; })
    gettext
    gtk2-x11
  ];

  # Upstream's platform presets define this, but nixpkgs invokes CMake directly.
  env.NIX_CFLAGS_COMPILE = "-D_GNU_SOURCE";

  # The tests compare rendered output pixel-for-pixel and vary by Cairo version.
  # Upstream runs them non-blockingly for the same reason.
  doCheck = false;

  meta = {
    description = "Gerber (RS-274X) viewer";
    mainProgram = "gerbv";
    homepage = "https://gerbv.github.io/";
    changelog = "https://github.com/gerbv/gerbv/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl2Plus;
    maintainers = with lib.maintainers; [ mog ];
    platforms = lib.platforms.unix;
  };
})
