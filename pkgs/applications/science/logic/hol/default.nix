{ lib
, stdenv
, fetchFromGitHub
, polyml
, graphviz
, makeFontsConf
, liberation_ttf
, experimentalKernel ? true
}:

stdenv.mkDerivation {
  pname = "hol4";
  version = "k.14";

  src = fetchFromGitHub {
    owner = "HOL-Theorem-Prover";
    repo = "HOL";
    rev = "kananaskis-14";
    sha256 = "sha256:0g4h8fks114wc9h61jwinin3xkjz7hy86l5bnd0cywj379b5zkxs";
  };

  nativeBuildInputs = [ polyml graphviz ];

  buildInputs = [ polyml ];

  FONTCONFIG_FILE = makeFontsConf {
    fontDirectories = [ liberation_ttf ];
  };

  patchPhase = ''
    echo $sourceRoot
    substituteInPlace tools/Holmake/Holmake_types.sml \
      --replace "\"/bin/" "\"" \
  '';

  # build happens in $out
  unpackPhase = ''
    runHook preUnpack
    cp -r $src $out
    sourceRoot=$out
    chmod -R u+w -- "$sourceRoot"
    runHook postUnpack
  '';

  configurePhase = ''
    poly < tools/smart-configure.sml
  '';

  buildPhase = ''
    bin/build ${if experimentalKernel then "--expk" else "--stdknl"}
  '';

  # TODO delete everything except bin/hol bin/hol.*
  # maybe move examples to share/hol/examples?
  installPhase = ''
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
    homepage = "https://hol-theorem-prover.org/";
    license = licenses.bsd3;
    platforms = platforms.unix;
    maintainers = with maintainers; [ mudri ];
  };
}
