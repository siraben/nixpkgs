{
  lib,
  cmake,
  dbus,
  fetchFromGitHub,
  pkg-config,
  qt6,
  stdenv,
  replaceVars,
  unzip,
  zip,
}:

let
  inherit (qt6)
    qtbase
    qtdeclarative
    qtsvg
    qttools
    wrapQtAppsHook
    ;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "vym";
  version = "3.0.0";

  src = fetchFromGitHub {
    owner = "insilmaril";
    repo = "vym";
    rev = "v${finalAttrs.version}";
    hash = "sha256-GS97QtBEkTTAwN54sk1BUQ79sFrz6tED9KfWTESi1vk=";
  };

  outputs = [
    "out"
    "man"
  ];

  patches = [
    (replaceVars ./patches/0000-fix-zip-paths.diff {
      zipPath = "${lib.getExe zip}";
      unzipPath = "${lib.getExe unzip}";
    })
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    qttools
    wrapQtAppsHook
  ];

  buildInputs = [
    dbus
    qtbase
    qtdeclarative
    qtsvg
  ];

  qtWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        unzip
        zip
      ]
    }"
  ];

  strictDeps = true;

  meta = {
    homepage = "http://www.insilmaril.de/vym/";
    description = "Mind-mapping software";
    longDescription = ''
      VYM (View Your Mind) is a tool to generate and manipulate maps which show
      your thoughts. Such maps can help you to improve your creativity and
      effectivity. You can use them for time management, to organize tasks, to
      get an overview over complex contexts, to sort your ideas etc.

      Maps can be drawn by hand on paper or a flip chart and help to structure
      your thoughts. While a tree like structure like shown on this page can be
      drawn by hand or any drawing software vym offers much more features to
      work with such maps.
    '';
    license = lib.licenses.gpl2Plus;
    mainProgram = "vym";
    maintainers = [ ];
    platforms = lib.platforms.linux;
  };
})
