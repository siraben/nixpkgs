{
  lib,
  stdenv,
  pkgsBuildBuild,
  qtModule,
  qtbase,
  qtdeclarative,
  openssl,
}:

qtModule {
  pname = "qtquick3d";
  propagatedBuildInputs = [
    qtbase
    qtdeclarative
  ];
  buildInputs = [ openssl ];
  cmakeFlags = lib.optionals (!stdenv.buildPlatform.canExecute stdenv.hostPlatform) [
    (lib.cmakeFeature "Qt6ShaderToolsTools_DIR" "${pkgsBuildBuild.qt6.qtshadertools}/lib/cmake/Qt6ShaderToolsTools")
    (lib.cmakeFeature "QT_ADDITIONAL_HOST_PACKAGES_PREFIX_PATH" (
      lib.concatMapStringsSep ";" (p: "${p}") [
        pkgsBuildBuild.qt6.qtdeclarative
        pkgsBuildBuild.qt6.qtshadertools
        pkgsBuildBuild.qt6.qtquick3d
      ]
    ))
  ];
}
