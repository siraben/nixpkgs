{
  lib,
  stdenv,
  fetchurl,
  libxcrypt,
  withoutInitTools ? false,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = if withoutInitTools then "sysvtools" else "sysvinit";
  version = "3.18";

  src = fetchurl {
    url = "https://codeberg.org/thejessesmith/sysvinit/releases/download/${finalAttrs.version}/sysvinit-${finalAttrs.version}.tar.xz";
    hash = "sha256-eT10J+IZ8czxIufFVlXO9fNBmtxiDsLuDtVX6MlLQ48=";
  };

  prePatch = ''
    # Patch some minimal hard references, so halt/shutdown work
    sed -i -e "s,/sbin/,$out/sbin/," src/halt.c src/init.c src/paths.h
  '';

  buildInputs = [ libxcrypt ];

  makeFlags = [
    "SULOGINLIBS=-lcrypt"
    "ROOT=$(out)"
    "usrdir="
  ];

  postInstall = ''
    mv $out/sbin/killall5 $out/bin
    ln -sf killall5 $out/bin/pidof
  ''
  + lib.optionalString withoutInitTools ''
    shopt -s extglob
    rm -rf $out/sbin/!(sulogin)
    rm -rf $out/include
    rm -rf $out/share/man/man5
    rm $(for i in $out/share/man/man8/*; do echo $i; done | grep -v 'pidof\|killall5')
    rm $out/bin/wall $out/share/man/man1/wall.1
  '';

  meta = {
    homepage = "https://codeberg.org/thejessesmith/sysvinit";
    changelog = "https://codeberg.org/thejessesmith/sysvinit/raw/tag/${finalAttrs.version}/doc/Changelog";
    description = "Utilities related to booting and shutdown";
    platforms = lib.platforms.linux;
    license = lib.licenses.gpl2Plus;
  };
})
