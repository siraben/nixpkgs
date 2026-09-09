{
  lib,
  stdenv,
  applyPatches,
  bundlerEnv,
  coreutils,
  fetchFromGitHub,
  flock,
  makeWrapper,
  ruby_3_4,
  runtimeShell,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dradis";
  version = "5.3.0";

  src = applyPatches {
    src = fetchFromGitHub {
      owner = "dradis";
      repo = "dradis-ce";
      tag = "v${finalAttrs.version}";
      hash = "sha256-CL/Yhgre7+pjfuaUa36MxyqD/e3Bl8JaK1vpIOH3Onw=";
    };
    postPatch = ''
      substituteInPlace Gemfile \
        --replace-fail "ruby '3.4.6'" "ruby '${ruby_3_4.version}'"
      substituteInPlace Gemfile.lock \
        --replace-fail "ruby 3.4.6p54" "ruby ${ruby_3_4.version}"
      substituteInPlace .ruby-version \
        --replace-fail "3.4.6" "${ruby_3_4.version}"
      substituteInPlace engines/dradis-{api,echo}/*.gemspec \
        --replace-fail '`git ls-files`.split($\)' 'Dir["**/*"]'
    '';
  };

  rubyEnv = bundlerEnv {
    name = "dradis-${finalAttrs.version}-gems";
    ruby = ruby_3_4;
    gemdir = finalAttrs.src;
    gemset = lib.recursiveUpdate (import ./gemset.nix) {
      dradis-api.source.path = finalAttrs.src + "/engines/dradis-api";
      dradis-echo.source.path = finalAttrs.src + "/engines/dradis-echo";
      libv8-node = {
        platform = "x86_64-linux";
        source.sha256 = "1259iqwprlv3axxrlmnrwhr3dvmz5hzdjipwk9qzx5hdh7ydwn3n";
      };
      thruster = {
        platform = "x86_64-linux";
        source.sha256 = "1nnyq1pzkqfsdrdycvzj9bacb5bg7dxkp3604c3r84f1jgja6yd9";
      };
    };
    groups = [ "default" ];
  };

  strictDeps = true;

  nativeBuildInputs = [
    finalAttrs.rubyEnv
    makeWrapper
    ruby_3_4
  ];

  env = {
    BUNDLE_WITHOUT = "development:test";
    RAILS_ENV = "production";
    NODE_ENV = "production";
  };

  buildPhase = ''
    runHook preBuild

    export HOME=$(mktemp -d)
    export BUNDLE_GEMFILE=$PWD/Gemfile
    export GEM_HOME=${finalAttrs.rubyEnv}/${ruby_3_4.gemPath}
    export GEM_PATH=$GEM_HOME
    patchShebangs bin
    cp config/database.yml.template config/database.yml
    mkdir -p app/views/tmp config/credentials log storage tmp

    SECRET_KEY_BASE_DUMMY=1 ${ruby_3_4}/bin/ruby bin/rails assets:precompile

    # Sprockets records build times in both its manifest and gzip headers and
    # gives each manifest a random name. Normalize those values.
    ${ruby_3_4}/bin/ruby -rjson -e '
      manifests = Dir["public/assets/.sprockets-manifest-*.json"]
      abort "expected one Sprockets manifest" unless manifests.length == 1
      manifest = manifests.first
      data = JSON.parse(File.read(manifest))
      data.fetch("files").each_value do |entry|
        entry["mtime"] = "1970-01-01T00:00:01+00:00"
      end
      fixed_manifest = "public/assets/.sprockets-manifest-#{"0" * 32}.json"
      File.write(fixed_manifest, JSON.generate(data))
      File.delete(manifest) unless manifest == fixed_manifest
      Dir["public/assets/**/*.gz"].each do |path|
        contents = File.binread(path)
        abort "invalid gzip file: #{path}" unless contents.start_with?("\x1f\x8b".b)
        contents[4, 4] = "\0" * 4
        File.binwrite(path, contents)
      end
    '

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/dradis" "$out/bin" "$out/libexec"
    cp -a . "$out/share/dradis"
    substitute ${./launcher.sh} "$out/libexec/dradis-launcher" \
      --replace-fail '#!/bin/sh' '#!${runtimeShell}'
    chmod +x "$out/libexec/dradis-launcher"

    # These paths must be writable. The launcher replaces them in its
    # per-user application tree before Rails starts.
    rm -rf \
      "$out/share/dradis/app/views/tmp" \
      "$out/share/dradis/config/credentials" \
      "$out/share/dradis/log" \
      "$out/share/dradis/storage" \
      "$out/share/dradis/tmp"

    for command in dradis dradis-rails; do
      makeWrapper "$out/libexec/dradis-launcher" "$out/bin/$command" \
        --prefix PATH : ${
          lib.makeBinPath [
            coreutils
            flock
          ]
        } \
        --set DRADIS_APP_SOURCE "$out/share/dradis" \
        --set DRADIS_COMMAND "$command" \
        --set DRADIS_VERSION "${finalAttrs.version}" \
        --set DRADIS_GEM_HOME "${finalAttrs.rubyEnv}/${ruby_3_4.gemPath}" \
        --set DRADIS_RUBY "${ruby_3_4}/bin/ruby"
    done

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    runtime_dir="$TMPDIR/dradis"
    test "$(DRADIS_DATA_DIR="$runtime_dir" HOME= XDG_DATA_HOME= \
      "$out/bin/dradis" --version)" = "dradis ${finalAttrs.version}"
    DRADIS_DATA_DIR="$runtime_dir" HOME= XDG_DATA_HOME= \
      "$out/bin/dradis-rails" db:prepare
    test "$(DRADIS_DATA_DIR="$runtime_dir" HOME= XDG_DATA_HOME= \
      "$out/bin/dradis-rails" runner \
      'print Dradis::CE::VERSION::STRING')" = "${finalAttrs.version}"
    set -- "$runtime_dir"/app-${finalAttrs.version}-*
    test "$#" -eq 1
    runtime_app=$1
    test -d "$runtime_app"
    for manifest in "$runtime_app"/public/assets/.sprockets-manifest-*.json; do
      test -f "$manifest"
      break
    done
    test "$(readlink "$runtime_app/storage")" = "$runtime_dir/storage"
    test -s "$runtime_dir/credentials/master.key"

    runHook postInstallCheck
  '';

  passthru.tests.version = testers.testVersion {
    package = finalAttrs.finalPackage;
    command = "dradis --version";
  };

  meta = {
    description = "Collaboration and reporting platform for information security teams";
    homepage = "https://dradis.com/ce/";
    changelog = "https://github.com/dradis/dradis-ce/blob/v${finalAttrs.version}/CHANGELOG";
    license = lib.licenses.gpl2Only;
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryNativeCode
    ];
    maintainers = with lib.maintainers; [ siraben ];
    mainProgram = "dradis";
    platforms = [ "x86_64-linux" ];
  };
})
