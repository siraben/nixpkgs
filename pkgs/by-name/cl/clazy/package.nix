{
  lib,
  fetchFromGitHub,
  llvmPackages,
  cmake,
  makeWrapper,
  versionCheckHook,
  gitUpdater,
}:

llvmPackages.stdenv.mkDerivation (finalAttrs: {
  pname = "clazy";
  version = "1.17.1";

  src = fetchFromGitHub {
    owner = "KDE";
    repo = "clazy";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Gjrex6UwlkAAvmyfsYWOD2s9mIq4zqnidGRj9f+slaI=";
  };

  buildInputs = [
    llvmPackages.llvm
    llvmPackages.libclang
  ];

  nativeBuildInputs = [
    cmake
    makeWrapper
  ];

  postInstall = ''
    wrapProgram $out/bin/clazy \
      --suffix PATH               : "${llvmPackages.clang}/bin/"                            \
      --suffix CPATH              : "$(<${llvmPackages.clang}/nix-support/libc-cflags)"     \
      --suffix CPATH              : "${llvmPackages.clang}/resource-root/include"           \
      --suffix CPLUS_INCLUDE_PATH : "$(<${llvmPackages.clang}/nix-support/libcxx-cxxflags)" \
      --suffix CPLUS_INCLUDE_PATH : "$(<${llvmPackages.clang}/nix-support/libc-cflags)"     \
      --suffix CPLUS_INCLUDE_PATH : "${llvmPackages.clang}/resource-root/include"

    wrapProgram $out/bin/clazy-standalone \
      --suffix CPATH              : "$(<${llvmPackages.clang}/nix-support/libc-cflags)"     \
      --suffix CPATH              : "${llvmPackages.clang}/resource-root/include"           \
      --suffix CPLUS_INCLUDE_PATH : "$(<${llvmPackages.clang}/nix-support/libcxx-cxxflags)" \
      --suffix CPLUS_INCLUDE_PATH : "$(<${llvmPackages.clang}/nix-support/libc-cflags)"     \
      --suffix CPLUS_INCLUDE_PATH : "${llvmPackages.clang}/resource-root/include"
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  doInstallCheck = true;
  versionCheckProgram = "${placeholder "out"}/bin/clazy-standalone";
  versionCheckProgramArg = "--version";
  preVersionCheck = "version=${lib.versions.majorMinor finalAttrs.version}";

  passthru = {
    updateScript = gitUpdater { rev-prefix = "v"; };
  };

  meta = {
    description = "Qt-oriented static code analyzer based on the Clang framework";
    homepage = "https://github.com/KDE/clazy";
    changelog = "https://github.com/KDE/clazy/blob/v${finalAttrs.version}/Changelog";
    license = lib.licenses.lgpl2Plus;
    maintainers = [ lib.maintainers.cadkin ];
    mainProgram = "clazy";
    platforms = lib.platforms.linux;
  };
})
