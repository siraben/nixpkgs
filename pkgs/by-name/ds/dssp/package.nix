{
  lib,
  stdenv,
  catch2_3,
  cmake,
  eigen,
  fetchFromGitHub,
  libcifpp,
  libmcfp,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dssp";
  version = "4.6.1";

  src = fetchFromGitHub {
    owner = "PDB-REDO";
    repo = "dssp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Wh19EG2mu9oYrIk2LmxwlXCF9Hhq3hU5ryY8Ni/y2YU=";
  };

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail 'DESTINATION ''${CIFPP_SHARE_DIR}' 'DESTINATION share/libcifpp'
  '';

  nativeBuildInputs = [ cmake ];

  checkInputs = [ catch2_3 ];

  buildInputs = [
    eigen
    libcifpp
    libmcfp
    zlib
  ];

  doCheck = true;

  meta = {
    description = "Calculate the most likely secondary structure assignment given the 3D structure of a protein";
    mainProgram = "mkdssp";
    homepage = "https://github.com/PDB-REDO/dssp";
    changelog = "https://github.com/PDB-REDO/dssp/blob/${finalAttrs.src.rev}/changelog";
    license = lib.licenses.bsd2;
    maintainers = with lib.maintainers; [ natsukium ];
    platforms = lib.platforms.unix;
  };
})
