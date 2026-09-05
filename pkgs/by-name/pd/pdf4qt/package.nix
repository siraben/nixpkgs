{
  lib,
  stdenv,
  fetchFromGitHub,
  lcms,
  cmake,
  pkg-config,
  qt6,
  wrapGAppsHook3,
  openjpeg,
  onetbb,
  blend2d,
  sane-backends,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pdf4qt";
  version = "1.6.0.0";

  src = fetchFromGitHub {
    owner = "JakubMelka";
    repo = "PDF4QT";
    tag = "v${finalAttrs.version}";
    hash = "sha256-c0XeJOsr8q8DG1BWqi61ZbZmJ8VkRG8EnGJMqRwEsPA=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.qttools
    qt6.wrapQtAppsHook
    # GLib-GIO-ERROR: No GSettings schemas are installed on the system
    wrapGAppsHook3
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtwayland
    qt6.qtsvg
    qt6.qtspeech
    lcms
    openjpeg
    onetbb
    blend2d
    sane-backends
  ];

  # `blend2d.h` moved to `blend2d/blend2d.h` in blend2d >= 0.21.2
  env.NIX_CFLAGS_COMPILE = "-I${blend2d.dev}/include/blend2d";

  cmakeFlags = [
    (lib.cmakeBool "PDF4QT_INSTALL_TO_USR" false)
  ];

  doCheck = true;

  dontWrapGApps = true;

  preFixup = ''
    qtWrapperArgs+=(''${gappsWrapperArgs[@]})
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Open source PDF editor";
    longDescription = ''
      This software is consisting of PDF rendering library,
      and several applications, such as advanced document
      viewer, command line tool, and document page
      manipulator application. Software is implementing PDF
      functionality based on PDF Reference 2.0.
    '';
    homepage = "https://jakubmelka.github.io";
    changelog = "https://github.com/JakubMelka/PDF4QT/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "Pdf4QtViewer";
    maintainers = with lib.maintainers; [ aleksana ];
    platforms = lib.platforms.linux;
  };
})
