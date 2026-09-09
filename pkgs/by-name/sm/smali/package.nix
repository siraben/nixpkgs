{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  gradle_8,
  jre_headless,
  makeWrapper,
  nix-update-script,
  runCommand,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "smali";
  version = "3.0.10";

  src = fetchFromGitHub {
    owner = "google";
    repo = "smali";
    tag = finalAttrs.version;
    hash = "sha256-Z5rzOVVqvME9Rd6WSKZqvXVAdGsBAH0xVocYGDJfN1o=";
  };

  strictDeps = true;

  patches = [
    # ANTLR otherwise emits the two labeled tokens in nondeterministic order.
    ./fix-nondeterministic-parser.patch
  ];

  nativeBuildInputs = [
    gradle_8
    makeWrapper
  ];

  mitmCache = gradle_8.fetchDeps {
    inherit (finalAttrs) pname;
    data = ./deps.json;
  };

  # Required for using the Gradle dependency cache on Darwin.
  __darwinAllowLocalNetworking = true;

  gradleBuildTask = ":smali:fatJar :baksmali:fatJar";

  doCheck = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 smali/build/libs/smali-${finalAttrs.version}-fat.jar \
      $out/share/smali/smali.jar
    install -Dm644 baksmali/build/libs/baksmali-${finalAttrs.version}-fat.jar \
      $out/share/smali/baksmali.jar

    makeWrapper ${lib.getExe jre_headless} $out/bin/smali \
      --add-flags "-jar $out/share/smali/smali.jar"
    makeWrapper ${lib.getExe jre_headless} $out/bin/baksmali \
      --add-flags "-jar $out/share/smali/baksmali.jar"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    $out/bin/smali --version | grep -F ${finalAttrs.version}
    $out/bin/baksmali --version | grep -F ${finalAttrs.version}

    runHook postInstallCheck
  '';

  passthru = {
    updateScript = nix-update-script { };

    tests.roundtrip = runCommand "smali-roundtrip-test" { } ''
      mkdir -p input output
      cat > input/HelloWorld.smali <<'EOF'
      .class public LHelloWorld;
      .super Ljava/lang/Object;

      .method public static main([Ljava/lang/String;)V
          .registers 2
          return-void
      .end method
      EOF

      ${lib.getExe finalAttrs.finalPackage} assemble input -o classes.dex
      ${finalAttrs.finalPackage}/bin/baksmali disassemble classes.dex -o output
      grep -F '.class public LHelloWorld;' output/HelloWorld.smali
      grep -F '.method public static main([Ljava/lang/String;)V' output/HelloWorld.smali
      touch $out
    '';
  };

  meta = {
    description = "Assembler and disassembler for Android's dex format";
    homepage = "https://github.com/google/smali";
    changelog = "https://github.com/google/smali/releases/tag/${finalAttrs.version}";
    license = with lib.licenses; [
      bsd3
      asl20
    ];
    mainProgram = "smali";
    maintainers = with lib.maintainers; [ siraben ];
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode # Gradle dependencies
    ];
    inherit (jre_headless.meta) platforms;
  };
})
