{
  lib,
  stdenv,
  fetchFromGitHub,
  unstableGitUpdater,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "m2libc";
  version = "0.2.1-unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "oriansj";
    repo = "M2libc";
    rev = "a65d93aaf4b439c4a12c093e15e3b253b151ba3f";
    hash = "sha256-Bhe1+jiSxw2Q2wANd51yPY98aNF7/ImZaIgKkCLVBZg=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/include
    cp -r . $out/include/M2libc

    runHook postInstall
  '';

  passthru.updateScript = unstableGitUpdater {
    url = "https://github.com/oriansj/M2libc";
    tagPrefix = "Release_";
  };

  meta = {
    description = "More standards compliant C library written in M2-Planet's C subset";
    homepage = "https://github.com/oriansj/m2libc";
    license = lib.licenses.gpl3Only;
    teams = [ lib.teams.minimal-bootstrap ];
    platforms = [
      "i686-linux"
      "x86_64-linux"
      "aarch64-linux"
      "riscv32-linux"
      "riscv64-linux"
    ];
  };
})
