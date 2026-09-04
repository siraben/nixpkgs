{
  stdenv,
  lib,
  fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "zsh-system-clipboard";
  version = "0.8.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "kutsan";
    repo = "zsh-system-clipboard";
    tag = "v${finalAttrs.version}";
    hash = "sha256-VWTEJGudlQlNwLOUfpo0fvh0MyA2DqV+aieNPx/WzSI=";
  };

  strictDeps = true;

  installPhase = ''
    runHook preInstall

    install -D zsh-system-clipboard.zsh \
      $out/share/zsh/${finalAttrs.pname}/zsh-system-clipboard.zsh

    runHook postInstall
  '';

  meta = {
    homepage = finalAttrs.src.meta.homepage;
    description = "Plugin that adds key bindings support for ZLE (Zsh Line Editor) clipboard operations for vi emulation keymaps";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [
      _0qq
      satoqz
    ];
    platforms = lib.platforms.all;
  };
})
