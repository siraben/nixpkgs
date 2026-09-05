{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  nodejs,
  yarn-berry_4,
}:

let
  yarn-berry = yarn-berry_4;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "asar";
  version = "4.3.0";

  src = fetchFromGitHub {
    owner = "electron";
    repo = "asar";
    tag = "v${finalAttrs.version}";
    hash = "sha256-TBn31tz8TBO7Gvku0ovgJ+AJj53Tm8m7plwts8EmhY8=";
  };

  postPatch = ''
    substituteInPlace package.json \
      --replace-fail '"version": "0.0.0-development"' '"version": "${finalAttrs.version}"'

    # Yarn 4.14 no longer supports the age-gate options used by upstream's
    # pinned Yarn 4.10 configuration.
    cat > .yarnrc.yml <<'EOF'
    nodeLinker: node-modules
    enableScripts: false
    compressionLevel: 0
    approvedGitRepositories:
      - "**"
    EOF
  '';

  missingHashes = ./missing-hashes.json;

  offlineCache = yarn-berry.fetchYarnBerryDeps {
    inherit (finalAttrs) src missingHashes;
    hash = "sha256-mdD7CSTlMmPP1t8g4mS61gHL0sVzUWZjTWPeFPKXQrc=";
  };

  nativeBuildInputs = [
    makeWrapper
    nodejs
    yarn-berry
    yarn-berry.yarnBerryConfigHook
  ];

  env.YARN_LOCKFILE_VERSION_OVERRIDE = 8;

  buildPhase = ''
    runHook preBuild

    yarn build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    yarn workspaces focus --production

    mkdir -p "$out/bin" "$out/lib/asar"
    cp -r bin lib node_modules package.json "$out/lib/asar"
    makeWrapper ${lib.getExe nodejs} "$out/bin/asar" \
      --add-flags "$out/lib/asar/bin/asar.mjs"

    runHook postInstall
  '';

  meta = {
    description = "Simple extensive tar-like archive format with indexing";
    homepage = "https://github.com/electron/asar";
    changelog = "https://github.com/electron/asar/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    mainProgram = "asar";
    maintainers = with lib.maintainers; [ xvapx ];
  };
})
