{
  stdenv,
  lib,
  fetchurl,
  findlib,
  ocaml,
  ocamlbuild,
  topkg,
}:

let
  minimumSupportedOcamlVersion = "4.02.0";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "hmap";
  version = "0.8.1";
  name = "ocaml${ocaml.version}-hmap-${finalAttrs.version}";

  src = fetchurl {
    url = "https://erratique.ch/software/hmap/releases/hmap-${finalAttrs.version}.tbz";
    sha256 = "10xyjy4ab87z7jnghy0wnla9wrmazgyhdwhr4hdmxxdn28dxn03a";
  };

  nativeBuildInputs = [
    ocaml
    ocamlbuild
    findlib
    topkg
  ];
  buildInputs = [ topkg ];

  strictDeps = true;

  inherit (topkg) installPhase;

  buildPhase = "${topkg.run} build --tests true";

  doCheck = true;

  checkPhase = "${topkg.run} test";

  meta = {
    description = "Heterogeneous value maps for OCaml";
    homepage = "https://erratique.ch/software/hmap";
    license = lib.licenses.isc;
    maintainers = [ lib.maintainers.pmahoney ];
    broken = !(lib.versionOlder minimumSupportedOcamlVersion ocaml.version);
  };
})
