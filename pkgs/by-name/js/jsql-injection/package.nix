{
  lib,
  copyDesktopItems,
  fetchFromGitHub,
  jdk21,
  jre,
  makeDesktopItem,
  maven,
  nix-update-script,
  runtimeShell,
  stripJavaArchivesHook,
  testers,
  xmlstarlet,
}:

maven.buildMavenPackage (finalAttrs: {
  pname = "jsql-injection";
  version = "0.115";

  strictDeps = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "ron190";
    repo = "jsql-injection";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ViD1io/xgEbmYwEpDrLmX+/0koV3htWaUBJ+/tti95c=";
  };

  # Upstream's test dependency graph contains dozens of database drivers and
  # probes three third-party repositories before Maven Central for every
  # artifact. They are not needed to build or run the application.
  postPatch = ''
    xmlstarlet ed --inplace -N m=http://maven.apache.org/POM/4.0.0 \
      -d '/m:project/m:modules/m:module[text()="build-tools"]' \
      -d '/m:project/m:profiles' \
      -d '/m:project/m:dependencyManagement/m:dependencies/m:dependency[m:artifactId="junit-bom" or m:artifactId="awaitility"]' \
      -d '/m:project/m:build/m:plugins/m:plugin[m:artifactId="jacoco-maven-plugin" or m:artifactId="maven-site-plugin" or m:artifactId="maven-scm-publish-plugin"]' \
      pom.xml

    xmlstarlet ed --inplace -N m=http://maven.apache.org/POM/4.0.0 \
      -d '/m:project/m:repositories' \
      -d '/m:project/m:reporting' \
      -d '/m:project/m:dependencies/m:dependency[m:scope="test"]' \
      -d '/m:project/m:build/m:plugins/m:plugin[m:artifactId="pitest-maven" or m:artifactId="gmavenplus-plugin" or m:artifactId="maven-surefire-plugin" or m:artifactId="maven-failsafe-plugin"]' \
      model/pom.xml

    xmlstarlet ed --inplace -N m=http://maven.apache.org/POM/4.0.0 \
      -d '/m:project/m:reporting' \
      -d '/m:project/m:dependencies/m:dependency[m:scope="test"]' \
      -d '/m:project/m:build/m:plugins/m:plugin[m:artifactId="pitest-maven" or m:artifactId="maven-surefire-plugin"]' \
      view/pom.xml
  '';

  mvnJdk = jdk21;
  mvnParameters = "-Dmaven.test.skip=true -Dproject.build.outputTimestamp=1980-01-01T00:00:02Z";
  mvnHash = "sha256-M5z72lXH4PXpmkyjaQBA1mBaXV4DYz64/hdaZQodHTk=";

  nativeBuildInputs = [
    copyDesktopItems
    stripJavaArchivesHook
    xmlstarlet
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "jsql-injection";
      desktopName = "jSQL Injection";
      comment = "Find database information through SQL injection";
      exec = "jsql-injection";
      icon = "jsql-injection";
      categories = [
        "System"
        "Security"
      ];
    })
  ];

  installPhase = ''
    runHook preInstall

    # The assembly JAR retains dependency license and notice files, unlike the
    # smaller shaded JAR whose upstream configuration excludes all META-INF.
    install -Dm644 view/target/view-v${finalAttrs.version}-jar-with-dependencies.jar \
      $out/share/jsql-injection/jsql-injection.jar
    install -Dm644 LICENCE.md $out/share/doc/jsql-injection/LICENCE.md
    install -Dm644 view/src/main/resources/swing/images/icons/app.svg \
      $out/share/icons/hicolor/scalable/apps/jsql-injection.svg

    mkdir -p $out/bin
    cat > $out/bin/jsql-injection <<'EOF'
    #!@shell@
    case "$1" in
      --help|-h)
        echo "Usage: jsql-injection [--help] [--version]"
        echo "Graphical tool for finding database information through SQL injection."
        ;;
      --version|-V)
        echo "jSQL Injection @version@"
        ;;
      *)
        exec @java@ -jar @jar@ "$@"
        ;;
    esac
    EOF
    substituteInPlace $out/bin/jsql-injection \
      --replace-fail '@shell@' '${runtimeShell}' \
      --replace-fail '@java@' '${lib.getExe' jre "java"}' \
      --replace-fail '@jar@' "$out/share/jsql-injection/jsql-injection.jar" \
      --replace-fail '@version@' '${finalAttrs.version}'
    chmod +x $out/bin/jsql-injection

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    test "$("$out/bin/jsql-injection" --version)" = "jSQL Injection ${finalAttrs.version}"
    "$out/bin/jsql-injection" --help | grep -F "Usage: jsql-injection"

    # Exercise the built JAR without a display or network access. Upstream checks
    # for a headless runtime before initializing its model and exits cleanly.
    if JAVA_TOOL_OPTIONS=-Djava.awt.headless=true \
      "$out/bin/jsql-injection" > headless.log 2>&1; then
      echo "jSQL Injection unexpectedly accepted a headless runtime" >&2
      exit 1
    fi
    grep -F "Headless runtime not supported" headless.log

    runHook postInstallCheck
  '';

  passthru = {
    tests.version = testers.testVersion {
      package = finalAttrs.finalPackage;
      command = "jsql-injection --version";
    };
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Java application for automatic SQL database injection";
    homepage = "https://github.com/ron190/jsql-injection";
    changelog = "https://github.com/ron190/jsql-injection/releases/tag/v${finalAttrs.version}";
    license = with lib.licenses; [
      gpl2Plus
      asl20 # DiffMatchPatch.java
      epl10 # Crc64Helper.java
    ];
    maintainers = with lib.maintainers; [ siraben ];
    mainProgram = "jsql-injection";
    inherit (jre.meta) platforms;
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode # Maven dependencies
    ];
  };
})
