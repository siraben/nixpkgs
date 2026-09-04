{
  lib,
  stdenvNoCC,
  fetchurl,
  installFonts,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-wenkai";
  version = "1.522";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwWenKai/releases/download/v${finalAttrs.version}/lxgw-wenkai-v${finalAttrs.version}.tar.gz";
    hash = "sha256-aBp31dACF146nhrw/G+iIBZMya1sFPHoQqU5h4584aQ=";
  };

  nativeBuildInputs = [ installFonts ];

  meta = {
    homepage = "https://lxgw.github.io/";
    description = "Open-source Chinese font derived from Fontworks' Klee One";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ ryanccn ];
  };
})
