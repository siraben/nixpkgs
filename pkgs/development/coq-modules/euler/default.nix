{ lib, mkCoqDerivation, coq, interval, version ? null }:
with lib;

mkCoqDerivation {
  owner = "taorunz";
  pname = "euler";

  release."74df69402ab5346c2b016f0ac7ed64cd805100ed".sha256 = "sha256-yIEd5DYcrehLqpYcru0TU6A6BELVjoUjGPaGoNFd1dM=";
  inherit version;
  defaultVersion = with versions; switch coq.coq-version [
    { case = range "8.10" "8.14"; out = "74df69402ab5346c2b016f0ac7ed64cd805100ed"; }
  ] null;

  preConfigure = ''
    substituteInPlace _CoqProject --replace "-R . Top" "-R . Euler"
  '';

  propagatedBuildInputs = [ interval ];

  meta = {
    description = "A quantum circuit language and formal verification tool";
    maintainers = with maintainers; [ siraben ];
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
