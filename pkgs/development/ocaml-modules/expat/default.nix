{
  stdenv,
  lib,
  fetchFromGitHub,
  expat,
  ocaml,
  findlib,
  ounit,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ocaml${ocaml.version}-expat";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "whitequark";
    repo = "ocaml-expat";
    rev = "v${finalAttrs.version}";
    hash = "sha256-eDA6MUcztaI+fpunWBdanNnPo9Y5gvbj/ViVcxYYEBg=";
  };

  prePatch = ''
    substituteInPlace Makefile --replace "gcc" "\$(CC)"
  '';

  nativeBuildInputs = [
    ocaml
    findlib
  ];
  buildInputs = [ expat ];

  strictDeps = true;

  doCheck = lib.versionAtLeast ocaml.version "4.08";
  checkTarget = "testall";
  checkInputs = [ ounit ];

  createFindlibDestdir = true;

  meta = {
    description = "OCaml wrapper for the Expat XML parsing library";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.vbgl ];
    inherit (finalAttrs.src.meta) homepage;
    inherit (ocaml.meta) platforms;
    broken = !(lib.versionAtLeast ocaml.version "4.02");
  };
})
