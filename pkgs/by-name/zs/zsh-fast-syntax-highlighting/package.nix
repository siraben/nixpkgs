{
  stdenvNoCC,
  lib,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "zsh-fast-syntax-highlighting";
  version = "1.56";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "zdharma-continuum";
    repo = "fast-syntax-highlighting";
    tag = "v${finalAttrs.version}";
    hash = "sha256-caVMOdDJbAwo8dvKNgwwidmxOVst/YDda7lNx2GvOjY=";
  };

  strictDeps = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    plugindir="$out/share/zsh/plugins/fast-syntax-highlighting"

    mkdir -p "$plugindir"
    cp -r -- {,_,-,.}fast-* *chroma themes "$plugindir"/

    runHook postInstall
  '';

  meta = {
    description = "Syntax-highlighting for Zshell";
    homepage = finalAttrs.src.meta.homepage;
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
  };
})
