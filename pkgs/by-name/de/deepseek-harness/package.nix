{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm_11,
  nodejs_24,
  makeBinaryWrapper,
  autoPatchelfHook,
  writableTmpDirAsHomeHook,
  nix-update-script,
}:

let
  nodejs = nodejs_24;
  pnpm = pnpm_11;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "deepseek-harness";
  version = "0.1.0-rc.7";

  src = fetchFromGitHub {
    owner = "deepseek-ai";
    repo = "deepseek-harness";
    tag = "dsh-v${finalAttrs.version}";
    hash = "sha256-xPP8FB308n8SD5B65whaErLyaDBbFferoQ9g3H6h2es=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeBinaryWrapper
    nodejs
    pnpm
    pnpmConfigHook
    writableTmpDirAsHomeHook
  ];

  buildInputs = [
    # libstdc++/libgcc_s for the prebuilt native addons (node-pty, koffi,
    # rolldown, lightningcss, ...) shipped in npm tarballs.
    stdenv.cc.cc.lib
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 4;
    hash = "sha256-zmlWt5HYvzkCnCDD5X/psgfGPbRAUwO0p4qDtI5+R5M=";
  };

  # pnpmConfigHook installs with --ignore-scripts, so the install scripts of
  # esbuild/node-pty/koffi/... never run; fix up the prebuilt ELF binaries
  # they ship manually. Only done once here (before the build needs them),
  # not again on the installed tree.
  dontAutoPatchelf = true;
  postConfigure = ''
    autoPatchelf node_modules
  '';

  preBuild = ''
    # The published @deepseek-ai/node-addon-landlock-run-linux-* npm packages
    # contain a prebuilt, statically linked Landlock launcher, but the git tag
    # only carries its C source (native/landlock-run/packages/entry/src/main.c,
    # ~300 lines of C11 over the raw kernel UAPI). Build it ourselves so the
    # Linux Landlock sandbox backend works; without the binary the runtime
    # probe deliberately fails closed and the harness falls back to other
    # sandbox backends (bwrap et al.).
    ${lib.optionalString (stdenv.hostPlatform.isGnu && (stdenv.hostPlatform.isx86_64 || stdenv.hostPlatform.isAarch64)) ''
      landlockPkg=native/landlock-run/packages/linux-${
        if stdenv.hostPlatform.isAarch64 then "arm64" else "x64"
      }
      mkdir -p "$landlockPkg/bin"
      # libc.a comes from glibc's `static` output; keep it out of buildInputs
      # and only put it on this command's search path, otherwise every link
      # in this derivation (e.g. makeBinaryWrapper's wrapper) would pick up
      # the static libc too.
      cc -O2 -static -L${stdenv.cc.libc.static}/lib -o "$landlockPkg/bin/landlock-run" \
        native/landlock-run/packages/entry/src/main.c
    ''}
  '';

  buildPhase = ''
    runHook preBuild

    # Builds the whole workspace: tsc project references + tsdown for the
    # host and client faces, then the vite build of the web frontend that
    # `dsh web` serves.
    pnpm run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/deepseek-harness
    cp -a . $out/lib/deepseek-harness

    # --expose-internals must come before the entry point so node treats it
    # as its own flag. The cordis plugin loader resolves bare plugin
    # specifiers (@deepseek-ai/cordis-plugin-timer, ...) against the profile
    # directory via Node's internal ESM loader; it only obtains that loader
    # with --expose-internals or through the node-addon-require-builtin
    # native addon, whose 0.1.4 prebuilds fail their V8 probing on node
    # 24.19 ("x64 sysv getter is not a recognized this->field accessor").
    # Without internals the loader falls back to plain import() from
    # vendor/loader, where no plugin package is resolvable, and every
    # profile fails to boot.
    makeBinaryWrapper ${lib.getExe nodejs} $out/bin/dsh \
      --add-flags "--expose-internals" \
      --add-flags "$out/lib/deepseek-harness/apps/cli/lib/bin.js" \
      --prefix PATH : ${lib.makeBinPath [ nodejs ]}

    runHook postInstall
  '';

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [ "--version-regex=dsh-v(.*)" ];
    };
  };

  meta = {
    description = "Open-source agent harness developed by DeepSeek AI where everything is a plugin";
    homepage = "https://github.com/deepseek-ai/deepseek-harness";
    changelog = "https://github.com/deepseek-ai/deepseek-harness/releases/tag/dsh-v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ siraben ];
    mainProgram = "dsh";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
