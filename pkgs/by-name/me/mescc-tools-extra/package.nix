{
  lib,
  stdenv,
  fetchFromGitHub,
  m2libc,
  nix-update-script,
  perl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mescc-tools-extra";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "oriansj";
    repo = "mescc-tools-extra";
    rev = "Release_${finalAttrs.version}";
    hash = "sha256-a2II2GOBFUPRwkRZQ0vEXysqdxxD1YWS5gZ3S+pGtis=";
  };

  # Don't use vendored M2libc
  postPatch = ''
    rmdir M2libc
    ln -s ${m2libc}/include/M2libc M2libc

    substituteInPlace makefile \
      --replace-fail 'COMMIT=$(shell git describe --dirty)' 'COMMIT=Release_${finalAttrs.version}'
  '';

  enableParallelBuilding = true;

  doCheck = true;
  checkTarget = "test";
  nativeCheckInputs = [ perl ];

  installFlags = [ "PREFIX=$(out)" ];

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version-regex=Release_(.*)" ];
  };

  meta = {
    description = "Collection of tools written for use in bootstrapping";
    homepage = "https://github.com/oriansj/mescc-tools-extra";
    license = lib.licenses.gpl3Only;
    teams = [ lib.teams.minimal-bootstrap ];
    inherit (m2libc.meta) platforms;
  };
})
