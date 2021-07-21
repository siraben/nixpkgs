{ lib, mkCoqDerivation, coq, compcert, version ? null }:

with lib; mkCoqDerivation rec {
  pname = "coq${coq.coq-version}-VST";
  namePrefix = [];
  displayVersion = { coq = false; };
  owner = "PrincetonUniversity";
  repo = "VST";
  fetcher = fetchFromGitHub {
    inherit owner repo;
    rev = releaseRev;
    sha256 = release."${version}".sha256;
    fetchSubmodules = true;
  };
  inherit version;
  defaultVersion = with versions; switch coq.coq-version [
    { case = range "8.12" "8.13"; out = "2.8"; }
  ] null;
  release."2.8".sha256 = "sha256-cyK88uzorRfjapNQ6XgQE0lbWnDsiyLve5po1VG52q0=";
  releaseRev = v: "v${v}";
  propagatedBuildInputs = [ compcert ];

  preConfigure = "patchShebangs util";

  makeFlags = [
    "BITSIZE=64"
    "COMPCERT=inst_dir"
    "COMPCERT_INST_DIR=${compcert.lib}/lib/coq/${coq.coq-version}/user-contrib/compcert"
    "INSTALLDIR=$(out)/lib/coq/${coq.coq-version}/user-contrib/VST"
  ];

  postInstall = ''
    for d in msl veric floyd sepcomp progs64
    do
      cp -r $d $out/lib/coq/${coq.coq-version}/user-contrib/VST/
    done
  '';

  meta = {
    description = "Verified Software Toolchain";
    homepage = "https://vst.cs.princeton.edu/";
    inherit (compcert.meta) platforms;
  };
}
