{ stdenvNoCC, lib, fetchurl, unzip }:

stdenvNoCC.mkDerivation rec {
  pname = "fasm-bin";

  version = "1.73.25";

  nativeBuildInputs = [ unzip ];

  src = fetchurl {
    url = "https://flatassembler.net/fasmg.j1gh.zip";
    sha256 = "0x1zzr8w97k0m8sz8wlyb5m5dmc8wdpp1f4azm5i26pcspsc2v8m";
  };
  unpackPhase = ''
    mkdir tmp
    unzip -d tmp $src
  '';

  installPhase = ''
    ls tmp/source/macos
    install -D tmp/${if stdenvNoCC.isDarwin
                     then "source/macos/x64/fasmg"
                     else "fasmg${lib.optionalString stdenvNoCC.isx86_64 ".x64"}"}\
               $out/bin/fasmg
  '';

  meta = with lib; {
    description = "x86(-64) macro assembler to binary, MZ, PE, COFF, and ELF";
    homepage = "https://flatassembler.net/download.php";
    license = licenses.bsd2;
    maintainers = with maintainers; [ orivej ];
    # platforms = [ "i686-linux" "x86_64-linux" ];
  };
}
