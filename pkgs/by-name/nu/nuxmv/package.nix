{
  lib,
  stdenv,
  autoPatchelfHook,
  fetchurl,
  makeWrapper,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "nuxmv";
  version = "2.2.0";

  src = fetchurl {
    url = "https://nuxmv.fbk.eu/downloads/${finalAttrs.version}/nuXmv-${finalAttrs.version}-${
      if stdenv.hostPlatform.isDarwin then "macos64" else "linux64"
    }.tar.xz";
    hash =
      if stdenv.hostPlatform.isDarwin then
        "sha256-xVJFPl4JXJGB59gAug/VeGdSwlt+Fr/5LBqyYW8AHQ0="
      else
        "sha256-0xcJiVri13N+HjxZ7slELHZSfSJzOA6v9vOuqMzp+UY=";
  };

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r usr/local/* $out/

    # Use Nixpkgs' glibc instead of the older bundled copy.
    rm -f $out/lib/*/libc.so.6 $out/lib/*/libm.so.6

    mkdir -p $out/share/doc/nuxmv
    mv $out/doc/* $out/share/doc/nuxmv/
    rmdir $out/doc
    install -Dm644 -t $out/share/doc/nuxmv LICENSE.txt NEWS.md README.md

    runHook postInstall
  '';

  postFixup = ''
    libdir=$(dirname "$(find "$out/lib" -name 'libnuxmv.*' -print -quit)")
    wrapProgram $out/bin/nuXmv \
      --set NUXMV_LIBRARY_PATH "$out/share/nuxmv" \
      --prefix ${
        if stdenv.hostPlatform.isDarwin then "DYLD_LIBRARY_PATH" else "LD_LIBRARY_PATH"
      } : "$libdir"
  '';

  passthru.tests.version = testers.testVersion {
    package = finalAttrs.finalPackage;
    command = "nuXmv -int";
  };

  meta = {
    description = "Symbolic model checker for analysis of finite and infinite state systems";
    homepage = "https://nuxmv.fbk.eu/";
    changelog = "https://nuxmv.fbk.eu/release-notes.html";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ siraben ];
    mainProgram = "nuXmv";
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
  };
})
