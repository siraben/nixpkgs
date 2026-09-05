{
  lib,
  stdenv,
  callPackage,
  fetchurl,
  fetchMavenArtifact,
  gitUpdater,
  mkRubyVersion,
  makeBinaryWrapper,
  jre,
}:

let
  # The version number here is whatever is reported by the RUBY_VERSION string
  rubyVersion = mkRubyVersion "4" "0" "0" "";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "jruby";
  version = "10.1.1.0";

  src = fetchurl {
    url = "https://repo1.maven.org/maven2/org/jruby/jruby-dist/${finalAttrs.version}/jruby-dist-${finalAttrs.version}-bin.tar.gz";
    hash = "sha256-Hgi/9qfwE0pHdPujfYz4i53UpzF71J/KWvaWoydFAUg=";
  };

  nativeBuildInputs = [ makeBinaryWrapper ];

  installPhase = ''
    mkdir -pv $out
    mv * $out
    mkdir -pv $out/share/jruby/docs
    rm $out/bin/*.{bat,dll,exe}
    mv $out/samples $out/share/jruby/
    mv $out/BSDL $out/COPYING $out/LEGAL $out/LICENSE* $out/share/jruby/docs/

    for i in $out/bin/{jruby,ruby}; do
      wrapProgram $i \
        --set JAVA_HOME ${jre.home}
    done

    # Bundler tries to create this directory
    mkdir -pv $out/${finalAttrs.passthru.gemPath}
    mkdir -p $out/nix-support
    cat > $out/nix-support/setup-hook <<EOF
      addGemPath() {
        addToSearchPath GEM_PATH \$1/${finalAttrs.passthru.gemPath}
      }

      addEnvHooks "$hostOffset" addGemPath
    EOF
  '';

  postFixup = ''
    PATH=$out/bin:$PATH patchShebangs $out/bin
  '';

  passthru = rec {
    rubyEngine = "jruby";
    gemPath = "lib/${rubyEngine}/gems/${rubyVersion.libDir}";
    libPath = "lib/${rubyEngine}/${rubyVersion.libDir}";
    devEnv = callPackage ../ruby/dev.nix {
      ruby = finalAttrs.finalPackage;
    };
    updateScript = gitUpdater {
      url = "https://github.com/jruby/jruby.git";
    };
  };

  meta = {
    description = "Ruby interpreter written in Java";
    homepage = "https://www.jruby.org/";
    changelog = "https://github.com/jruby/jruby/releases/tag/${finalAttrs.version}";
    license = with lib.licenses; [
      cpl10
      gpl2
      lgpl21
    ];
    platforms = jre.meta.platforms;
    maintainers = [ lib.maintainers.fzakaria ];
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
  };
})
