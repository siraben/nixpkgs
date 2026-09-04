{
  lib,
  stdenv,
  fetchFromGitHub,
  unstableGitUpdater,
}:

stdenv.mkDerivation {
  pname = "exifprobe";
  version = "2.0.1-unstable-2020-12-30";

  src = fetchFromGitHub {
    owner = "hfiguiere";
    repo = "exifprobe";
    rev = "eee65ff3c62fed3fff35e690230820bd80c90381";
    hash = "sha256-jALJ6odQqeJGfQjmL3JBzbcmlj35KGoV6+b+NsWAfuQ=";
  };

  env.CFLAGS = toString [ "-O2" ];

  installFlags = [ "DESTDIR=$(out)" ];

  postInstall = ''
    mv $out/usr/bin $out/bin
    mv $out/usr/share $out/share
    rm -r $out/usr
  '';

  passthru.updateScript = unstableGitUpdater {
    url = "https://github.com/hfiguiere/exifprobe";
  };

  meta = {
    description = "Tool for reading EXIF data from image files produced by digital cameras";
    homepage = "https://github.com/hfiguiere/exifprobe";
    license = lib.licenses.bsd2;
    maintainers = with lib.maintainers; [ siraben ];
    mainProgram = "exifprobe";
    platforms = lib.platforms.unix;
  };
}
