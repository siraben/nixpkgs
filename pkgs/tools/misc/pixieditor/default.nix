{ stdenv, fetchFromGitHub, buildDotnetPackage }:

buildDotnetPackage rec {
  baseName = "PixiEditor";
  version = "0.1.3.6";

  src = fetchFromGitHub {
    owner = "PixiEditor";
    repo = "PixiEditor";
    rev = "${version}";
    sha256 = "0glr4w5n8hr1g63ail7q3ma5pq84zhf8vzf099hb8h55wd9yr6lj";
  };

  buildInputs = [ ];

  meta = with stdenv.lib; {
    description = "A lightweight pixel art editor made with .NET 5";
    homepage = "https://github.com/PixiEditor/PixiEditor";
    license = stdenv.lib.licenses.mit;
    maintainers = with maintainers; [ siraben ];
    platforms = stdenv.lib.platforms.unix;
  };
}
