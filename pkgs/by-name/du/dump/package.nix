# Tested with simple dump and restore -i, but complains that
# /nix/store/.../etc/dumpdates doesn't exist.

{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  e2fsprogs,
  libuuid,
  ncurses,
  readline,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dump";
  version = "0.4b55";

  src = fetchurl {
    url = "mirror://sourceforge/dump/dump-${finalAttrs.version}.tar.gz";
    sha256 = "sha256-FBfBFrzHKgIE+O5WycnXfbw5tn1ML2j753/51qgeEwM=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    e2fsprogs
    libuuid
    ncurses
    readline
    zlib
  ];

  configureFlags = [ "--disable-werror" ];

  meta = {
    homepage = "https://dump.sourceforge.io/";
    description = "Linux Ext2 filesystem dump/restore utilities";
    license = lib.licenses.bsd3;
    maintainers = [ ];
    platforms = lib.platforms.linux;
  };
})
