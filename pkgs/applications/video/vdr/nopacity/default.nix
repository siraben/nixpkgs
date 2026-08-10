{
  stdenv,
  lib,
  fetchFromGitLab,
  vdr,
  graphicsmagick,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "vdr-skin-nopacity";
  version = "1.1.20";

  src = fetchFromGitLab {
    repo = "SkinNopacity";
    owner = "kamel5";
    hash = "sha256-50oCb9xixPQEwv3Ni1UUmmWVzky/MTvZaqSUczhsHWc=";
    tag = finalAttrs.version;
  };

  buildInputs = [
    vdr
    graphicsmagick
  ];

  installFlags = [ "DESTDIR=$(out)" ];

  meta = {
    inherit (finalAttrs.src.meta) homepage;
    description = "Highly customizable native true color skin for the Video Disc Recorder";
    maintainers = [ lib.maintainers.ck3d ];
    license = lib.licenses.gpl2;
    inherit (vdr.meta) platforms;
  };
})
