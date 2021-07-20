{ lib, stdenv, polyml, fetchFromGitHub, graphviz, fontconfig, liberation_ttf
, experimentalKernel ? true }:

let
  vnum = "14";
  version = "k.${vnum}";
  longVersion = "kananaskis-${vnum}";
  holsubdir = "hol-${longVersion}";
  kernelFlag = if experimentalKernel then "--expk" else "--stdknl";
  polymlEnableShared = lib.overrideDerivation polyml (attrs: {
    configureFlags = [ "--enable-shared" ];
  });
in

stdenv.mkDerivation {
  pname = "hol4";
  inherit version;

  src = fetchFromGitHub {
    owner = "HOL-Theorem-Prover";
    repo = "HOL";
    rev = longVersion;
    sha256 = "sha256-us9fVjpDcs9As6tQgzw8X84+bLSRy2BgYpyEoKdDkDw=";
  };

  buildInputs = [ polymlEnableShared graphviz fontconfig liberation_ttf ];

  patchPhase = ''
    mkdir chroot-fontconfig
    cat ${fontconfig.out}/etc/fonts/fonts.conf > chroot-fontconfig/fonts.conf
    sed -e 's@</fontconfig>@@' -i chroot-fontconfig/fonts.conf
    echo "<dir>${liberation_ttf}</dir>" >> chroot-fontconfig/fonts.conf
    echo "</fontconfig>" >> chroot-fontconfig/fonts.conf
    export FONTCONFIG_FILE=$(pwd)/chroot-fontconfig/fonts.conf
    substituteInPlace tools/Holmake/Holmake_types.sml \
      --replace "\"/bin/" "\"" \
  '';

  configurePhase = ''
    poly < tools/smart-configure.sml
  '';

  buildPhase = ''
    bin/build ${kernelFlag}
  '';

  installPhase = ''
    find ./bin -type f -exec install -D -m 0755 {} -t $out/bin \;
    find ./doc -type f -exec install -D -m 0644 {} -t $out/doc \;
    find ./help -type f -exec install -D -m 0644 {} -t $out/doc \;
    find ./examples -type f -exec install -D {} -t $out/examples \;
  '';

  meta = with lib; {
    description = "Interactive theorem prover based on Higher-Order Logic";
    longDescription = ''
      HOL4 is the latest version of the HOL interactive proof
      assistant for higher order logic: a programming environment in
      which theorems can be proved and proof tools
      implemented. Built-in decision procedures and theorem provers
      can automatically establish many simple theorems (users may have
      to prove the hard theorems themselves!) An oracle mechanism
      gives access to external programs such as SMT and BDD
      engines. HOL4 is particularly suitable as a platform for
      implementing combinations of deduction, execution and property
      checking.
    '';
    homepage = "http://hol.sourceforge.net/";
    license = licenses.bsd3;
    platforms = platforms.unix;
    maintainers = with maintainers; [ mudri siraben ];
  };
}
