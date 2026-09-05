{
  lib,
  stdenv,
  catch2_3,
  cmake,
  eigen,
  fast-float,
  fetchFromGitHub,
  pcre2,
  pkg-config,
  sqlite,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libcifpp";
  version = "10.0.4";

  src = fetchFromGitHub {
    owner = "PDB-REDO";
    repo = "libcifpp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-+lD543SYLoHrds97en4zfDHkQBf4wL0NOg2LcshJI8k=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  checkInputs = [ catch2_3 ];

  cmakeFlags = [
    # disable network access
    "-DCIFPP_DOWNLOAD_CCD=OFF"
  ];

  buildInputs = [
    eigen
    fast-float
  ];

  propagatedBuildInputs = [
    pcre2
    sqlite
    zlib
  ];

  doCheck = true;

  meta = {
    description = "Manipulate mmCIF and PDB files";
    homepage = "https://github.com/PDB-REDO/libcifpp";
    changelog = "https://github.com/PDB-REDO/libcifpp/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.bsd2;
    maintainers = with lib.maintainers; [ natsukium ];
    platforms = lib.platforms.unix;
  };
})
