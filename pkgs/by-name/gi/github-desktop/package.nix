{
  lib,
  stdenv,
  stdenvNoCC,
  copyDesktopItems,
  fetchFromGitHub,
  fetchurl,
  fetchYarnDeps,
  makeBinaryWrapper,
  makeDesktopItem,
  runCommand,
  unzip,
  yarnBuildHook,
  yarnConfigHook,

  electron,
  git,
  git-lfs,
  node-gyp,
  nodejs,
  pkg-config,
  python3,
  typescript_5,
  zip,

  gnome-keyring,
  libsecret,
  curl,
}:

let
  version = "3.6.5";

  darwinSources = {
    aarch64-darwin = fetchurl {
      url = "https://github.com/desktop/desktop/releases/download/release-${version}/GitHub.Desktop-arm64.zip";
      hash = "sha256-A447SD2DiWYS8jItDEqBENayry2Pjy6c2N+n/olN4xU=";
    };
  };

  commonMeta = {
    description = "GUI for managing Git and GitHub";
    homepage = "https://desktop.github.com";
    changelog = "https://desktop.github.com/release-notes";
    downloadPage = "https://desktop.github.com/download";
    license = lib.licenses.mit;
    mainProgram = "github-desktop";
    maintainers = with lib.maintainers; [ dtomvan ];
  };

  commonPassthru = {
    sources = darwinSources;
    updateScript = ./update.sh;
  };

  inherit (stdenv.hostPlatform.node) arch platform;
  cacheRootHash = "sha256-WruQopxE9uROdbBFiMsjuQj7jlEdNrbhWym6JxGIBi8=";
  cacheAppHash = "sha256-YlqykBZXcvWOkb07ojZsnWdJTb/OKbDeXh1VpATGS2M=";

  linux = stdenv.mkDerivation (finalAttrs: {
    pname = "github-desktop";
    inherit version;

    src = fetchFromGitHub {
      owner = "desktop";
      repo = "desktop";
      tag = "release-${finalAttrs.version}";
      hash = "sha256-oAv+hcIVxRtNdiP027IXyBOiL3LRQS8QZZtfenqU3Eo=";
      fetchSubmodules = true;
      postCheckout = "git -C $out rev-parse HEAD > $out/.gitrev";
    };

    yarnBuildScript = "build:prod";

    buildInputs = [
      gnome-keyring
      libsecret
      curl
    ];

    nativeBuildInputs = [
      copyDesktopItems
      makeBinaryWrapper
      yarnBuildHook
      yarnConfigHook

      git
      nodejs
      node-gyp
      pkg-config
      python3
      # desktop-notifications build doesn't pick up tsc from node_modules for some reason
      typescript_5
      zip
    ];

    env = {
      ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
      npm_config_nodedir = electron.headers;
    };

    cacheRoot = fetchYarnDeps {
      name = "${finalAttrs.pname}-cache-root";
      yarnLock = finalAttrs.src + "/yarn.lock";
      hash = cacheRootHash;
    };

    cacheApp = fetchYarnDeps {
      name = "${finalAttrs.pname}-cache-app";
      yarnLock = finalAttrs.src + "/app/yarn.lock";
      hash = cacheAppHash;
    };

    dontYarnInstallDeps = true;

    postConfigure = ''
      yarnOfflineCache="$cacheRoot" runHook yarnConfigHook

      pushd app
      yarnOfflineCache="$cacheApp" runHook yarnConfigHook
      popd

      yarn --cwd app/node_modules/desktop-notifications run install

      # use git from nixpkgs instead of an automatically downloaded one by dugite
      gitRoot=app/node_modules/dugite/git
      makeWrapper ${lib.getExe git} "$gitRoot/bin/git" \
        --prefix PATH : ${lib.makeBinPath [ git-lfs ]}

      mkdir -p "$gitRoot/libexec/git-core"

      for script in ${git}/libexec/git-core/*; do
        ln -s "$script" "$gitRoot/libexec/git-core/$(basename "$script")"
      done

      # exception: printenvz needs `node-gyp` configure first for some reason
      pushd node_modules/printenvz
      node node_modules/.bin/node-gyp configure
      popd

      declare -a natives=(
        app/node_modules/fs-admin
        app/node_modules/keytar
        app/node_modules/desktop-trampoline
        app/node_modules/windows-argv-parser
        node_modules/printenvz
      )
      for native in "''${natives[@]}"; do
        yarn --offline --cwd $native build
      done

      # exception: desktop-trampoline doesn't include `node-gyp rebuild` in its build script anymore
      pushd app/node_modules/desktop-trampoline
      node-gyp rebuild
      popd

      yarn compile:script

      touch electron
      zip -0Xqr electron-v${electron.version}-${platform}-${arch}.zip electron
      rm electron

      substituteInPlace script/build.ts \
        --replace-fail "return packager({" "return packager({electronZipDir:\"$(pwd)\",electronVersion: \"${electron.version}\","
    '';

    preBuild = ''
      export CIRCLE_SHA1="$(cat .gitrev)"
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "github-desktop";
        desktopName = "GitHub Desktop";
        comment = "Focus on what matters instead of fighting with Git";
        exec = "github-desktop %u";
        icon = "github-desktop";
        mimeTypes = [
          "x-scheme-handler/x-github-client"
          "x-scheme-handler/x-github-desktop-auth"
          "x-scheme-handler/x-github-desktop-dev-auth"
        ];
        terminal = false;
      })
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/github-desktop

      # transpose [name][size] into [size][name]
      for icon in app/static/logos/*.png; do
        size="$(basename "$icon" .png)"
        install -Dm444 "$icon" -T "$out/share/icons/hicolor/$size/github-desktop.png"
      done

      cp -r dist/*/resources $out/share/github-desktop

      makeWrapper ${lib.getExe electron} $out/bin/github-desktop \
        --add-flag $out/share/github-desktop/resources/app \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
        --inherit-argv0

      mkdir -p $out/share/icons/hicolor/512x512/apps
      ln -s $out/share/github-desktop/resources/app/static/icon-logo.png $out/share/icons/hicolor/512x512/apps/github-desktop.png

      runHook postInstall
    '';

    passthru = commonPassthru // {
      inherit (finalAttrs) cacheRoot cacheApp;
    };

    meta = commonMeta // {
      platforms = lib.lists.intersectLists electron.meta.platforms lib.platforms.linux;
    };
  });

  darwin = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "github-desktop";
    inherit version;

    __structuredAttrs = true;
    strictDeps = true;

    src =
      darwinSources.${stdenvNoCC.hostPlatform.system}
        or (throw "github-desktop: unsupported system ${stdenvNoCC.hostPlatform.system}");

    sourceRoot = ".";

    nativeBuildInputs = [ unzip ];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      app="GitHub Desktop.app"
      test -d "$app"
      test -x "$app/Contents/MacOS/GitHub Desktop"

      mkdir -p "$out/Applications" "$out/bin"
      cp -R "$app" "$out/Applications/"
      ln -s \
        "../Applications/GitHub Desktop.app/Contents/MacOS/GitHub Desktop" \
        "$out/bin/github-desktop"

      runHook postInstall
    '';

    # Preserve the upstream signature and notarization metadata.
    dontFixup = true;

    passthru = commonPassthru // {
      tests.install-layout =
        runCommand "github-desktop-darwin-install-layout"
          {
            nativeBuildInputs = [ python3 ];
          }
          ''
            app="${finalAttrs.finalPackage}/Applications/GitHub Desktop.app"
            executable="$app/Contents/MacOS/GitHub Desktop"

            test -d "$app"
            test -x "$executable"
            test -L "${finalAttrs.finalPackage}/bin/github-desktop"
            test "$(readlink "${finalAttrs.finalPackage}/bin/github-desktop")" = \
              "../Applications/GitHub Desktop.app/Contents/MacOS/GitHub Desktop"

            python3 - "$app/Contents/Info.plist" "$executable" "${finalAttrs.version}" <<'PY'
            import pathlib
            import plistlib
            import struct
            import sys

            plist_path = pathlib.Path(sys.argv[1])
            executable_path = pathlib.Path(sys.argv[2])
            expected_version = sys.argv[3]
            with plist_path.open("rb") as file:
                plist = plistlib.load(file)
            assert plist["CFBundleShortVersionString"] == expected_version
            assert plist["CFBundleExecutable"] == "GitHub Desktop"
            with executable_path.open("rb") as file:
                magic, cpu_type = struct.unpack("<II", file.read(8))
            assert magic == 0xFEEDFACF
            assert cpu_type == 0x0100000C
            PY

            touch "$out"
          '';
    };

    meta = commonMeta // {
      platforms = builtins.attrNames darwinSources;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  });
in
if stdenv.hostPlatform.isDarwin then darwin else linux
