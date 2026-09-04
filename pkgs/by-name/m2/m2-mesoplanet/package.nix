{
  lib,
  stdenv,
  fetchFromGitHub,
  m2libc,
  m2-planet,
  mescc-tools,
  mescc-tools-extra,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "m2-mesoplanet";
  version = "1.13.0";

  src = fetchFromGitHub {
    owner = "oriansj";
    repo = "M2-Mesoplanet";
    rev = "Release_${finalAttrs.version}";
    hash = "sha256-GLvVU8+bbA/RpTCzfHq6xAScHlzi/SeVKMWUwfIS+tc=";
  };

  # Don't use vendored M2libc
  postPatch = ''
    rmdir M2libc
    ln -s ${m2libc}/include/M2libc M2libc

    substituteInPlace makefile \
      --replace-fail 'COMMIT=$(shell git describe --dirty)' 'COMMIT=Release_${finalAttrs.version}'
    substituteInPlace test/test0004/run_test.sh \
      --replace-fail 'TMPDIR="test/test0004/tmp"' 'TMPDIR="$PWD/test/test0004/tmp"'
  '';

  # Upstream overrides the optimisation to be -O0, which is incompatible with fortify. Let's disable it.
  hardeningDisable = [ "fortify" ];

  doCheck = true;
  checkTarget = "test";
  nativeCheckInputs = [
    m2-planet
    mescc-tools
  ];

  preCheck = ''
    mkdir -p test-bin
    ln -s ${mescc-tools-extra}/bin/catm test-bin/
    export PATH="$PWD/test-bin:$PATH"
  '';

  installPhase = ''
    runHook preInstall

    install -D bin/M2-Mesoplanet $out/bin/M2-Mesoplanet

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version-regex=Release_(.*)" ];
  };

  meta = {
    description = "Macro Expander Saving Our m2-PLANET";
    homepage = "https://github.com/oriansj/M2-Mesoplanet";
    license = lib.licenses.gpl3Only;
    teams = [ lib.teams.minimal-bootstrap ];
    inherit (m2libc.meta) platforms;
    mainProgram = "M2-Mesoplanet";
  };
})
