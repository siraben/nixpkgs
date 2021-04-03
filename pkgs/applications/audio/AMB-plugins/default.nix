{ lib, stdenv, fetchurl, ladspaH
}:

stdenv.mkDerivation rec {
  pname = "AMB-plugins";
  version = "0.8.1";
  src = fetchurl {
    url = "http://kokkinizita.linuxaudio.org/linuxaudio/downloads/${pname}-${version}.tar.bz2";
    sha256 = "0x4blm4visjqj0ndqr0cg776v3b7lvplpc8cgi9n51llhavn0jpl";
  };

  buildInputs = [ ladspaH ];

  postPatch = ''
    substituteInPlace Makefile \
      --replace "/usr/bin/install" "install" \
      --replace "/bin/rm" "rm" \
      --replace "/usr/lib/ladspa" "$out/lib/ladspa" \
      --replace "g++" "c++"
  '';

  preInstall = ''
    mkdir -p $out/lib/ladspa
  '';

  meta = {
    description = "A set of ambisonics ladspa plugins";
    longDescription = ''
      Mono and stereo to B-format panning, horizontal rotator, square, hexagon and cube decoders.
    '';
    version = version;
    homepage = "http://kokkinizita.linuxaudio.org/linuxaudio/ladspa/index.html";
    license = lib.licenses.gpl2Plus;
    maintainers = [ lib.maintainers.magnetophon ];
    platforms = lib.platforms.unix;
  };
}
