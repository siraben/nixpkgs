{
  lib,
  fetchFromGitHub,
  qt6,
  legendary-gl,
  python3Packages,
}:

let
  rare-legendary = legendary-gl.overridePythonAttrs (oldAttrs: {
    version = "0.20.35";

    src = fetchFromGitHub {
      owner = "RareDevs";
      repo = "legendary";
      tag = "rare-1.12.0.155";
      hash = "sha256-3HBeIGNPwoCLQyirmU1j73emLpiJaYix6hqpIsN9dQ8=";
    };

    dependencies = oldAttrs.dependencies ++ [ python3Packages.requests-futures ];
  });
in
python3Packages.buildPythonApplication (finalAttrs: {
  pname = "rare";
  version = "1.12.0.155";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "RareDevs";
    repo = "Rare";
    tag = finalAttrs.version;
    hash = "sha256-sqLBYzOgqGFHwbcvHiP8boh/ZQAgjQygkWsQ+M+Zj24=";
  };

  nativeBuildInputs = [
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtwayland
  ];

  build-system = with python3Packages; [
    setuptools
    setuptools-scm
  ];

  dependencies = with python3Packages; [
    orjson
    pypresence
    pyside6
    qstylizer
    qtawesome
    rare-legendary
    requests
    vdf
  ];

  postPatch = ''
    # PySide6-Essentials is the PyPI subset of the full pyside6 package.
    substituteInPlace pyproject.toml \
      --replace-fail '"PySide6-Essentials >= 6.8.1"' '"PySide6 >= 6.8.1"'
  '';

  env.SETUPTOOLS_SCM_PRETEND_VERSION = finalAttrs.version;

  dontWrapQtApps = true;

  postInstall = ''
    install -Dm644 misc/rare.desktop -t $out/share/applications/
    install -Dm644 $out/${python3Packages.python.sitePackages}/rare/resources/images/Rare.png $out/share/icons/rare.png
  '';

  preFixup = ''
    makeWrapperArgs+=("''${qtWrapperArgs[@]}")
  '';

  # Project has no tests
  doCheck = false;

  pythonImportsCheck = [ "rare.widgets.rare_app" ];

  meta = {
    description = "GUI for Legendary, an Epic Games Launcher open source alternative";
    homepage = "https://github.com/RareDevs/Rare";
    maintainers = [ ];
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "rare";
  };
})
