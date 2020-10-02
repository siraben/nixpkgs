{ stdenv, fetchFromGitHub, cmake, asciidoc, libxslt, docbook_xsl }:

stdenv.mkDerivation rec {
  pname = "mktiupgrade";
  version = "unstable-2020-01-28";

  src = fetchFromGitHub {
    owner = "KnightOS";
    repo = "mktiupgrade";
    rev = "86790df33df5d6b9ea20d7dab9299c3494be0ba7";
    sha256 = "1zkh71y4s6v6f2qxpx0v1j1kihlfxy9m9sk6w0zlzpa2vskfg71n";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [ asciidoc libxslt.bin docbook_xsl ];

  hardeningDisable = [ "format" ];

  meta = with stdenv.lib; {
    homepage    = "https://knightos.org/";
    description = "Packages KnightOS distribution files into a ROM";
    license     = licenses.mit;
    maintainers = with maintainers; [ siraben ];
  };
}
