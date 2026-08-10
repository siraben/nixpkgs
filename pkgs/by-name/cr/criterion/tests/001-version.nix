{
  stdenv,
  pkg-config,
  criterion,
}:
stdenv.mkDerivation (finalAttrs: {
  name = "version-tester";
  inherit (criterion) version;
  src = ./test_dummy.c;

  dontUnpack = true;
  buildInputs = [ criterion ];
  nativeBuildInputs = [ pkg-config ];

  buildPhase = ''
    cc -o version-tester $src `pkg-config --libs criterion`
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp version-tester $out/bin/version-tester
  '';

  meta.mainProgram = "version-tester";
})
