{
  lib,
  stdenv,
  vdr,
  fetchFromGitHub,
  ffmpeg,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "vdr-markad";
  version = "4.2.22";

  src = fetchFromGitHub {
    repo = "vdr-plugin-markad";
    owner = "kfb77";
    hash = "sha256-Sp9saT/w3QwLEz9mo4kMUrXMXc5S/DOxm4nN1FPEgtk=";
    tag = "V${finalAttrs.version}";
  };

  buildInputs = [
    vdr
    ffmpeg
  ];

  postPatch = ''
    substituteInPlace command/Makefile --replace '/usr' ""

    substituteInPlace plugin/markad.cpp \
      --replace "/usr/bin" "$out/bin" \
      --replace "/var/lib/markad" "$out/var/lib/markad"

    substituteInPlace command/markad-standalone.cpp \
      --replace "/var/lib/markad" "$out/var/lib/markad"
  '';

  buildFlags = [
    "DESTDIR=$(out)"
    "VDRDIR=${vdr.dev}/lib/pkgconfig"
  ];

  installFlags = finalAttrs.buildFlags;

  meta = {
    inherit (finalAttrs.src.meta) homepage;
    description = "Plugin for VDR that marks advertisements";
    mainProgram = "markad";
    maintainers = [ lib.maintainers.ck3d ];
    inherit (vdr.meta) platforms license;
  };
})
