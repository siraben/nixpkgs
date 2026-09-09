{
  lib,
  stdenv,
  bundlerEnv,
  bundlerUpdateScript,
  coreutils,
  curl,
  espeak,
  fetchFromGitHub,
  gnugrep,
  lame,
  nodejs,
  ruby_3_4,
  runCommand,
  which,
}:

let
  rubyEnv = bundlerEnv {
    name = "beef-xss-gems";
    gemdir = ./.;
    groups = [
      "ext_dns"
      "ext_msf"
      "ext_notifications"
      "ext_qrcode"
      "geoip"
    ];
    ruby = ruby_3_4;
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "beef-xss";
  version = "0.6.0.0";

  src = fetchFromGitHub {
    owner = "beefproject";
    repo = "beef";
    tag = "v${finalAttrs.version}";
    hash = "sha256-W76xklDZfXK3r5Q+wqC9Rqnw96XSjQRAdi11fjZiQ3w=";
  };

  postPatch = ''
    # Keep the persistent database outside the versioned writable runtime tree.
    substituteInPlace beef \
      --replace-fail \
        "db_file = config.get('beef.database.file')" \
        "db_file = File.expand_path(config.get('beef.database.file'), ENV.fetch('BEEF_XSS_DATA_DIR', Dir.pwd))"

    # The release's config.yaml was not updated alongside VERSION.
    substituteInPlace config.yaml \
      --replace-fail "version: '0.5.4.0'" "version: '${finalAttrs.version}'"
  '';

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/beef-xss
    cp -a . $out/share/beef-xss

    substitute ${./beef-xss} $out/bin/beef-xss \
      --replace-fail '@ruby@' '${rubyEnv.wrappedRuby}/bin/ruby' \
      --replace-fail '@app@' "$out/share/beef-xss" \
      --replace-fail '@version@' '${finalAttrs.version}' \
      --replace-fail '@mkdir@' '${coreutils}/bin/mkdir' \
      --replace-fail '@mktemp@' '${coreutils}/bin/mktemp' \
      --replace-fail '@cp@' '${coreutils}/bin/cp' \
      --replace-fail '@chmod@' '${coreutils}/bin/chmod' \
      --replace-fail '@mv@' '${coreutils}/bin/mv' \
      --replace-fail '@rm@' '${coreutils}/bin/rm' \
      --replace-fail '@runtimePath@' '${
        lib.makeBinPath [
          espeak
          lame
          nodejs
          which
        ]
      }'
    chmod +x $out/bin/beef-xss
    ln -s beef-xss $out/bin/beef

    runHook postInstall
  '';

  nativeInstallCheckInputs = [ gnugrep ];
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    $out/bin/beef-xss --help | grep -F 'Usage: beef [options]'
    $out/bin/beef --help | grep -F 'Usage: beef [options]'

    runHook postInstallCheck
  '';

  passthru = {
    tests.smoke =
      runCommand "beef-xss-smoke-test"
        {
          nativeBuildInputs = [
            curl
            finalAttrs.finalPackage
            gnugrep
          ];
        }
        ''
          export HOME="$TMPDIR/home"
          export BEEF_XSS_STATE_DIR="$TMPDIR/state"
          export BEEF_XSS_CONFIG_DIR="$TMPDIR/config"
          mkdir -p "$HOME" "$BEEF_XSS_CONFIG_DIR"
          cp ${finalAttrs.finalPackage}/share/beef-xss/config.yaml "$BEEF_XSS_CONFIG_DIR/config.yaml"
          substituteInPlace "$BEEF_XSS_CONFIG_DIR/config.yaml" \
            --replace-fail 'passwd: "beef"' 'passwd: "nix-smoke-test"' \
            --replace-fail 'port: "3000"' 'port: "39123"'

          beef-xss >beef.log 2>&1 &
          server_pid=$!
          trap 'kill "$server_pid" 2>/dev/null || true' EXIT

          for _ in $(seq 1 60); do
            if curl --fail --silent --noproxy '*' http://127.0.0.1:39123/hook.js >hook.js; then
              break
            fi
            sleep 1
          done

          if ! grep -Fq 'BEEFHOOK' hook.js \
            || [ ! -s "$BEEF_XSS_STATE_DIR/beef.db" ] \
            || [ ! -s "$BEEF_XSS_STATE_DIR/runtime-${finalAttrs.version}/extensions/admin_ui/media/javascript-min/web_ui_all.js" ]; then
            cat beef.log
            exit 1
          fi

          kill "$server_pid"
          wait "$server_pid" || true
          trap - EXIT
          grep -F 'BeEF server started' beef.log
          touch $out
        '';
    updateScript = bundlerUpdateScript "beef-xss";
  };

  meta = {
    description = "Browser Exploitation Framework";
    homepage = "https://beefproject.com/";
    changelog = "https://github.com/beefproject/beef/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [ siraben ];
    mainProgram = "beef-xss";
    platforms = lib.platforms.linux;
  };
})
