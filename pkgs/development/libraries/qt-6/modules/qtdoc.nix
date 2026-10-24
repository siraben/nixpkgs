{
  lib,
  buildPackages,
  qtModule,
  qtdeclarative,
  qtbase,
}:

let
  docTools = buildPackages.qt6.qttools.override { withClang = true; };
in
qtModule {
  pname = "qtdoc";
  # avoid fix-qt-builtin-paths hook substitute QT_INSTALL_DOCS to qtdoc's path
  postPatch = ''
    for file in $(grep -rl '$QT_INSTALL_DOCS'); do
      substituteInPlace $file \
          --replace '$QT_INSTALL_DOCS' "${qtbase}/share/doc"
    done
  '';
  nativeBuildInputs = [ docTools ];
  propagatedBuildInputs = [ qtdeclarative ];

  cmakeFlags = [
    (lib.cmakeFeature "QT_OPTIONAL_TOOLS_PATH" "${docTools}")
    (lib.cmakeFeature "QT_ADDITIONAL_HOST_PACKAGES_PREFIX_PATH" "${buildPackages.qt6.qtdeclarative}")
  ];

  ninjaFlags = [ "docs" ];
  installTargets = [ "install_docs" ];
}
