{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  pkg-config,
  asciidoc,
  cryptsetup,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "luksmeta";
  version = "10";

  src = fetchFromGitHub {
    owner = "latchset";
    repo = "luksmeta";
    tag = "v${finalAttrs.version}";
    hash = "sha256-oasodAfUOgq2s0l+MIfCBTMo0ouXy73prVDnjLfMJA8=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    asciidoc
  ];
  buildInputs = [ cryptsetup ];

  meta = {
    description = "Simple library for storing metadata in the LUKSv1 header";
    mainProgram = "luksmeta";
    homepage = "https://github.com/latchset/luksmeta/";
    maintainers = with lib.maintainers; [ fpletz ];
    license = lib.licenses.lgpl21Plus;
  };
})
