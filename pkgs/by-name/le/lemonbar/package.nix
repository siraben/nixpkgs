{
  lib,
  stdenv,
  fetchFromGitHub,
  perl,
  libxcb,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lemonbar";
  version = "1.5";

  strictDeps = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "LemonBoy";
    repo = "bar";
    tag = "v${finalAttrs.version}";
    hash = "sha256-OLhgu0kmMZhjv/VST8AXvIH+ysMq72m4TEOypdnatlU=";
  };

  nativeBuildInputs = [ perl ];

  buildInputs = [ libxcb ];

  installFlags = [
    "DESTDIR=$(out)"
    "PREFIX="
  ];

  meta = {
    description = "Lightweight xcb based bar";
    homepage = "https://github.com/LemonBoy/bar";
    maintainers = with lib.maintainers; [
      meisternu
      moni
    ];
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "lemonbar";
  };
})
