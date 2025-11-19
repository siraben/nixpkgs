{stdenv, fetchurl, readline, ghc, perl, m4, gmp, ncurses}:

stdenv.mkDerivation (rec {
  name = "ghc-6.8.2";
  homepage = "http://www.haskell.org/ghc";

  src = map fetchurl [
    { url = "http://tarballs.nixos.org/md5/43108417594be7eba0918c459e871e40";
      name = "${name}-src.tar.bz2";
      md5 = "43108417594be7eba0918c459e871e40";
    }
    { url = "http://tarballs.nixos.org/md5/d199c50814188fb77355d41058b8613c";
      name = "${name}-src-extralibs.tar.bz2";
      md5 = "d199c50814188fb77355d41058b8613c";
    }
  ];

  buildInputs = [ghc readline perl m4 gmp];

  setupHook = ./setup-hook.sh;

  meta = {
    description = "The Glasgow Haskell Compiler";
  };

  postInstall = ''
    ensureDir "$out/nix-support"
    echo "# Path to the GHC compiler directory in the store" > $out/nix-support/setup-hook
    echo "ghc=$out" >> $out/nix-support/setup-hook
    echo ""         >> $out/nix-support/setup-hook
    cat $setupHook  >> $out/nix-support/setup-hook
  '';

  configureFlags=[
    "--with-gmp-libraries=${gmp}/lib"
    "--with-readline-libraries=${readline}/lib"
    "--with-gmp-includes=${gmp}/include"
    "--with-gcc=${gcc}/bin/gcc"
  ];

  preConfigure = "
    # still requires a hack for ncurses
    sed -i \"s|^\\\(ld-options.*$\\\)|\\\1 -L${ncurses}/lib|\" libraries/readline/readline.buildinfo.in
  ";

  inherit (stdenv) gcc;
  inherit readline gmp ncurses;
})
