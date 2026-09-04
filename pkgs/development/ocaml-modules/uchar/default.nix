{
  stdenv,
  fetchurl,
  ocaml,
  findlib,
  ocamlbuild,
  opaline,
  withShared ? true,
  lib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ocaml${ocaml.version}-uchar";
  version = "0.0.2";

  src = fetchurl {
    url = "https://github.com/ocaml/uchar/releases/download/v${finalAttrs.version}/uchar-${finalAttrs.version}.tbz";
    sha256 = "1w2saw7zanf9m9ffvz2lvcxvlm118pws2x1wym526xmydhqpyfa7";
  };

  nativeBuildInputs = [
    ocaml
    ocamlbuild
    findlib
  ];

  strictDeps = true;

  buildPhase = "ocaml pkg/build.ml native=true native-dynlink=${lib.boolToString withShared}";
  installPhase = "${opaline}/bin/opaline -libdir $OCAMLFIND_DESTDIR";
  configurePlatforms = [ ];

  meta = {
    description = "Compatibility library for OCaml’s Uchar module";
    inherit (ocaml.meta) platforms license;
    maintainers = [ lib.maintainers.vbgl ];
  };
})
