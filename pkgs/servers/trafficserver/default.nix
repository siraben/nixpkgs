{ stdenv, lib, fetchFromGitHub, autoreconfHook, perl, openssl, pcre, zlib }:

stdenv.mkDerivation rec {
  pname = "trafficserver";
  version = "9.0.0";

  src = fetchFromGitHub {
    owner = "apache";
    repo = pname;
    rev = version;
    sha256 = "sha256-PmfgZGs0A5A21UpShPsBpzZULZPJYnbyeJLNuPgmeh8=";
  };

  nativeBuildInputs = [ autoreconfHook perl ];

  buildInputs = [ openssl pcre zlib ];

  configureFlags = [ "--with-experimental-plugins" ];

  meta = with lib; {
    homepage = "https://trafficserver.apache.org";
    description = "A fast, scalable and extensible HTTP/1.1 and HTTP/2 compliant caching proxy server";
    longDescription = ''
      Traffic Server is a high-performance building block for cloud services.
      It's more than just a caching proxy server; it also has support for
      plugins to build large scale web applications.
    '';
    license = licenses.asl20;
    maintainers = with maintainers; [ siraben ];
    platforms = platforms.all;
  };
}
