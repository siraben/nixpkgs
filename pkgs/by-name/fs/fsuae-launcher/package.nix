{
  lib,
  fetchurl,
  fsuae,
  gettext,
  python3Packages,
  stdenv,
  libsForQt5,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "fs-uae-launcher";
  version = "3.2.35";

  src = fetchurl {
    url = "https://github.com/FrodeSolheim/fs-uae-launcher/releases/download/v${finalAttrs.version}/fs-uae-launcher-${finalAttrs.version}.tar.xz";
    hash = "sha256-zf10zZkoGTGpBDQNQUx+vETdvdDQ1Zmz65gY1YEF3CU=";
  };

  nativeBuildInputs = [
    gettext
    python3Packages.python
    libsForQt5.wrapQtAppsHook
  ];

  buildInputs = with python3Packages; [
    lhafile
    pillow
    pyopengl
    pyqt5
    requests
    setuptools
  ];

  strictDeps = true;

  makeFlags = [ "prefix=$(out)" ];

  dontWrapQtApps = true;

  postPatch = ''
    substituteInPlace setup.py \
      --replace-fail "distutils.core" "setuptools"
    substituteInPlace fsbc/seven_zip_file.py \
      --replace-fail "from distutils.spawn import find_executable" "from shutil import which as find_executable"
  '';

  preFixup = ''
    wrapQtApp "$out/bin/fs-uae-launcher" \
      --set PYTHONPATH "$PYTHONPATH"

    # fs-uae-launcher search side by side for executables and shared files
    # see $src/fsgs/plugins/pluginexecutablefinder.py#find_executable
    ln -s ${fsuae}/bin/fs-uae $out/bin
    ln -s ${fsuae}/bin/fs-uae-device-helper $out/bin
    ln -s ${fsuae}/share/fs-uae $out/share/fs-uae
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    homepage = "https://fs-uae.net";
    description = "Graphical front-end for the FS-UAE emulator";
    license = lib.licenses.gpl2Plus;
    mainProgram = "fs-uae-launcher";
    platforms = with lib.systems.inspect; patternLogicalAnd patterns.isx86 patterns.isLinux;
  };
})
