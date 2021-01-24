{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, qtbase, libtiff, libjpeg,
  qtquickcontrols, libraw, curl, libarchive, librtprocess }:

stdenv.mkDerivation rec {
  pname = "filmulator";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "CarVac";
    repo = "filmulator-gui";
    rev = "v${version}";
    sha256 = "0gdw4mxawh8lh4yvq521h3skjc46fpb0wvycy4sl2cm560d26sy6";
  };

  sourceRoot = "source/filmulator-gui";

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libtiff curl libarchive qtbase qtquickcontrols librtprocess ];

  meta = with lib; {
    description = "Simplified raw editing with the power of film";
    homepage = "https://github.com/CarVac/filmulator";

    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ siraben ];
    platforms = platforms.unix;
  };
}
