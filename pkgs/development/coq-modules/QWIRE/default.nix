{ lib, mkCoqDerivation, coq, version ? null }:
with lib;

mkCoqDerivation {
  owner = "inQWIRE";
  pname = "QWIRE";

  release."330f1d7d98f528476d880c9b0e6fbd2ba3e1c0ea".sha256 = "sha256-j6AC86r1Jv1AvvQHtfuUIMWg7sgCgHcZyfrRAq9W0Iw=";
  inherit version;
  defaultVersion = with versions; switch coq.coq-version [
    { case = range "8.12" "8.14"; out = "330f1d7d98f528476d880c9b0e6fbd2ba3e1c0ea"; }
  ] null;

  preConfigure = ''
    substituteInPlace _CoqProject --replace "-R . Top" "-R . QWIRE"
  '';

  meta = {
    description = "A quantum circuit language and formal verification tool";
    maintainers = with maintainers; [ siraben ];
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
