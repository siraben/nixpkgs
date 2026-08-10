{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  kdePackages,
  gettext,
  fcitx5,
  libhangul,
  nixosTests,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "fcitx5-hangul";
  version = "5.1.10";

  src = fetchFromGitHub {
    owner = "fcitx";
    repo = "fcitx5-hangul";
    rev = finalAttrs.version;
    hash = "sha256-ZeBTJ9SllLSVHt7kJOQL+q2SGjQkyYqD5SCXWj1QojE=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    kdePackages.extra-cmake-modules
    gettext
  ];

  buildInputs = [
    fcitx5
    libhangul
  ];

  passthru.tests = {
    inherit (nixosTests) fcitx5;
  };

  meta = {
    description = "Hangul wrapper for Fcitx5";
    homepage = "https://github.com/fcitx/fcitx5-hangul";
    license = lib.licenses.lgpl21Plus;
    maintainers = with lib.maintainers; [ xrelkd ];
    platforms = lib.platforms.linux;
  };
})
