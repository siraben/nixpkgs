{ lib, mkCoqDerivation, coq, QWIRE, euler, version ? null }:
with lib;

let
  euler-src = fetchFromGitHub {
    
  };
in

mkCoqDerivation {
  owner = "inQWIRE";
  pname = "SQIR";

  release."dd192e73a82c4338ad7fb278f3b6a9cee5bc409b".sha256 = "sha256-1w0ZBHwlx1gH5OHDpidcPtIpanYKD64ShAhkRjd9yCg=";
  inherit version;
  defaultVersion = with versions; switch coq.coq-version [
    { case = range "8.12" "8.14"; out = "dd192e73a82c4338ad7fb278f3b6a9cee5bc409b"; }
  ] null;

  propagatedBuildInputs = [ QWIRE euler ];

  # useDune2 = true;

  preConfigure = ''
    substituteInPlace Makefile --replace "git submodule init" ""
    substituteInPlace Makefile --replace "git submodule update" ""
    sed _CoqProject -i -e "/QWIRE/d"
    substituteInPlace _CoqProject --replace "-R . Top" "-R . SQIR"
  '';

  

  meta = {
    description = "A Small Quantum Intermediate Representation";
    longDescription = ''
      SQIR is a Small Quantum Intermediate Representation for quantum
      programs. Its intended use is as an intermediate representation in a
      Verified Optimizer for Quantum Circuits (VOQC).
    '';
    maintainers = with maintainers; [ siraben Zimmi48 ];
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
