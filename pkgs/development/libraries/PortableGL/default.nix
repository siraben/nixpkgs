{ lib, stdenv, fetchFromGitHub, SDL2, assimp }:

stdenv.mkDerivation rec {
  pname = "PortableGL";
  version = "unstable-2021-12-18";

  src = fetchFromGitHub {
    owner = "rswinkle";
    repo = "PortableGL";
    rev = "1baeb4d96faf95cdff0081111df9fbc153c1d3aa";
    sha256 = "sha256-CtOrLUmh0dp8KW3dynqkDqgOQPCcNyYdzG9Q82337Uk=";
  };

  sourceRoot = "source/demos";
  buildInputs = [ SDL2 assimp ];

  installPhase= ''
    runHook preInstall
      mkdir -p $out/bin
      for f in $(find . -executable -type f);
      do
        cp $f $out/bin/
      done
    runHook postInstall
  '';


  meta = with lib; {
    description = "An implementation of OpenGL 3.x-ish in clean C";
    homepage = "https://github.com/rswinkle/PortableGL";
    license = licenses.mit;
    maintainers = with maintainers; [ siraben ];
    platforms = platforms.all;
  };
}
