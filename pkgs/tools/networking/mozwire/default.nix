{ pkgs, stdenv, fetchFromGitHub }:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "MozWire";
  version = "0.4.1";

  src = fetchFromGitHub {
    owner = "NilsIrl";
    repo = pname;
    rev = "v${version}";
    sha256 = "1slfb6m22vzglnrxahlhdcwzwpf3b817mskdx628s92mjzngzyih";
  };

  cargoSha256 = "0b00j8vn1vvvphcyv8li7i73pq66sq6dr4wc1w4s3pppa151xr55";
  verifyCargoDeps = true;

  meta = with stdenv.lib; {
    description = "MozillaVPN configuration manager giving Linux, macOS users\
(among others), access to MozillaVPN.";
    homepage = https://github.com/NilsIrl/MozWire;
    license = licenses.gpl3;
    maintainers = with maintainers; [ siraben nilsirl ];
    platforms = platforms.all;
  };
}

