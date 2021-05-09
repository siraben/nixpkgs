{ lib, mkCoqDerivation, coq, mathcomp-algebra, mathcomp-finmap
, hierarchy-builder, version ? null }: with lib;

mkCoqDerivation {
  pname = "graph-theory";

  release."0.8".rev    = "v0.8";
  release."0.8".sha256 = "sha256-gwKfUa74fI07j+2eQgnLD70swjCtOFGHGaIWb4qI0n4=";

  inherit version;
  defaultVersion = with versions; switch coq.coq-version [
    { case = isGe "8.12"; out = "0.8"; }
  ] null;

  propagatedBuildInputs = [ mathcomp-algebra mathcomp-finmap hierarchy-builder ];

  meta = {
    description = "General topology in Coq";
    longDescription = ''
      This library develops some of the basic concepts and results of
      general topology in Coq.
    '';
    maintainers = with maintainers; [ siraben ];
    license = licenses.cecill-b;
  };
}
