{ lib, clangStdenv, fetchzip }:

clangStdenv.mkDerivation rec {
  pname = "zchaff";
  version = "2007.3.12";

  src = fetchzip {
    url = "https://www.princeton.edu/~chaff/zchaff/zchaff.64bit.${version}.zip";
    sha256 = "sha256-88fAtJb7o+Qv2GohTdmquxMEq4oCbiKbqLFmS7zs1Ak=";
  };

  patches = [ ./sat_solver.patch ];
  makeFlags = [ "CC=${clangStdenv.cc.targetPrefix}c++" ];
  installPhase= ''
    runHook preInstall
    install -Dm755 -t $out/bin zchaff
    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://www.princeton.edu/~chaff/zchaf";
    description = "Accelerated SAT Solver from Princeton";
    license = licenses.mit;
    maintainers = with maintainers; [ siraben ];
    platforms = platforms.unix;
  };
}
