{
  lib,
  fetchFromGitHub,
  makeDesktopItem,
  makeWrapper,
  gradle_8,
  jdk17,
  jre,
  libxxf86vm,
  gitUpdater,
  libGL,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "runelite";
  version = "2.8.0";

  src = fetchFromGitHub {
    owner = "runelite";
    repo = "launcher";
    tag = finalAttrs.version;
    hash = "sha256-1IUjbZEvoHb2Fer16rIvi6shMsol+hiPLQleXHRVLEU=";
  };

  gradle = gradle_8.override { java = jdk17; };

  nativeBuildInputs = [
    finalAttrs.gradle
    makeWrapper
  ];

  mitmCache = finalAttrs.gradle.fetchDeps {
    inherit (finalAttrs) pname;
    data = ./deps.json;
  };

  gradleBuildTask = "shadowJar";
  # UpdaterTest fetches Apple's external plist DTD.
  gradleCheckTask = "checkstyleMain checkstyleTest test --tests net.runelite.launcher.VersionTest";
  gradleFlags = [ "-PRUNELITE_BUILD=runelite" ];
  doCheck = true;

  desktop = makeDesktopItem {
    name = "RuneLite";
    type = "Application";
    exec = "runelite";
    icon = "runelite";
    comment = "Open source Old School RuneScape client";
    desktopName = "RuneLite";
    genericName = "Oldschool Runescape";
    categories = [ "Game" ];
    startupWMClass = "net-runelite-launcher-Launcher";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons
    mkdir -p $out/share/applications

    cp build/libs/RuneLite.jar $out/share
    cp appimage/runelite.png $out/share/icons

    ln -s ${finalAttrs.desktop}/share/applications/RuneLite.desktop $out/share/applications/RuneLite.desktop

    makeWrapper ${jre}/bin/java $out/bin/runelite \
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          libxxf86vm
          libGL
        ]
      }" \
      --add-flags "-jar $out/share/RuneLite.jar"

    runHook postInstall
  '';

  passthru.updateScript = gitUpdater { };

  meta = {
    description = "Open source Old School RuneScape client";
    homepage = "https://runelite.net/";
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode
    ];
    license = lib.licenses.bsd2;
    maintainers = with lib.maintainers; [
      kmeakin
      moody
    ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "runelite";
  };
})
