{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  shellspec,
  busybox-sandbox-shell,
  ksh,
  mksh,
  yash,
  zsh,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "getoptions";
  version = "3.3.2";

  strictDeps = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "ko1nksm";
    repo = "getoptions";
    tag = "v${finalAttrs.version}";
    hash = "sha256-hapOGPibqt2Mm6k73v63gHxrX+lifZ8xcwzj8vWbtgo=";
  };

  makeFlags = [ "PREFIX=${placeholder "out"}" ];

  doCheck = true;

  nativeCheckInputs = [
    shellspec
    ksh
    mksh
    yash
    zsh
  ]
  ++ lib.lists.optional (!stdenvNoCC.hostPlatform.isDarwin) busybox-sandbox-shell;

  # Disable checks against yash, since shellspec seems to be broken for yash>=2.54
  # (see: https://github.com/NixOS/nixpkgs/pull/218264#pullrequestreview-1434402054)
  preCheck = ''
    substituteInPlace Makefile \
      --replace-fail "shellspec -s posh" "true" \
      --replace-fail "shellspec -s yash" "true"
  ''
  + lib.strings.optionalString stdenvNoCC.hostPlatform.isDarwin ''
    substituteInPlace Makefile \
      --replace-fail "shellspec -s 'busybox ash'" "true"
  '';

  checkTarget = "test_in_various_shells";

  meta = {
    description = "Elegant option/argument parser for shell scripts (full support for bash and all POSIX shells)";
    homepage = "https://github.com/ko1nksm/getoptions";
    changelog = "https://github.com/ko1nksm/getoptions/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    license = lib.licenses.cc0;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ matrss ];
    mainProgram = "getoptions";
  };
})
