{
  lib,
  stdenv,
  fetchurl,
  mrustc,
  mrustc-minicargo,
  llvm_20,
  libffi,
  cmake,
  perl,
  python3,
  zlib,
  libxml2,
  pkg-config,
  curl,
  which,
  time,
}:

let
  mrustcTargetVersion = "1.90";
  rustcVersion = "1.90.0";
  rustcSrc = fetchurl {
    url = "https://static.rust-lang.org/dist/rustc-${rustcVersion}-src.tar.gz";
    hash = "sha256-eZqfnLpO1TUeBxBIvPa1VgdV2QCWSN7zOkB91JYfm34=";
  };
  rustcDir = "rustc-${rustcVersion}-src";
  outputDir = "output-${rustcVersion}";
  platforms = [ "x86_64-linux" ];
in

stdenv.mkDerivation (finalAttrs: {
  pname = "mrustc-bootstrap";
  version = "${mrustc.version}_${rustcVersion}";

  inherit (mrustc) src;
  postUnpack = "tar -xf ${rustcSrc} -C source/";

  # The rust build system rejects checksum changes nix would make.
  dontFixLibtool = true;
  # rustc carries cmake in tree to build llvm-rt; the normal path doesn't
  # need it, so don't run cmake's configure hook on the mrustc tree.
  dontUseCmakeConfigure = true;

  patches = [ ./patches/0001-dont-download-rustc-1.90.patch ];

  postPatch = ''
    echo "applying patch ./rustc-${rustcVersion}-src.patch"
    patch -p0 -d ${rustcDir}/ < rustc-${rustcVersion}-src.patch
  '';

  strictDeps = true;
  nativeBuildInputs = [
    cmake
    mrustc
    mrustc-minicargo
    perl
    pkg-config
    python3
    time
    which
  ];
  buildInputs = [
    # for rustc
    llvm_20
    libffi
    zlib
    libxml2
    # for cargo
    curl
  ];

  makeFlags = [
    # Use shared mrustc/minicargo/llvm instead of rebuilding them
    "MRUSTC=${mrustc}/bin/mrustc"
    "MINICARGO=${mrustc-minicargo}/bin/minicargo"
    "LLVM_CONFIG=${llvm_20.dev}/bin/llvm-config"
    "RUSTC_TARGET=${stdenv.targetPlatform.rust.rustcTarget}"
  ];

  buildPhase = ''
    runHook preBuild

    local flagsArray=(
      PARLEVEL=$NIX_BUILD_CORES
      ${toString finalAttrs.makeFlags}
    )

    touch ${rustcDir}/dl-version
    export OUTDIR_SUF=-${rustcVersion}
    export RUSTC_VERSION=${rustcVersion}
    export MRUSTC_TARGET_VER=${mrustcTargetVersion}
    export MRUSTC_PATH=${mrustc}/bin/mrustc

    echo minicargo.mk: libs
    make -f minicargo.mk "''${flagsArray[@]}" LIBS

    echo test
    make "''${flagsArray[@]}" test

    # disabled because it expects ./bin/mrustc
    #echo local_tests
    #make "''${flagsArray[@]}" local_tests

    echo minicargo.mk: rustc
    make -f minicargo.mk "''${flagsArray[@]}" ${outputDir}/rustc

    echo minicargo.mk: cargo
    make -f minicargo.mk "''${flagsArray[@]}" ${outputDir}/cargo

    echo run_rustc
    make -C run_rustc "''${flagsArray[@]}"

    unset flagsArray

    runHook postBuild
  '';

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    run_rustc/${outputDir}/prefix/bin/hello_world | grep -i "hello, world"
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin/ $out/lib/
    cp run_rustc/${outputDir}/prefix/bin/cargo $out/bin/cargo
    cp run_rustc/${outputDir}/prefix/bin/rustc_binary $out/bin/rustc

    cp -r run_rustc/${outputDir}/prefix/lib/* $out/lib/
    cp $out/lib/rustlib/${stdenv.targetPlatform.rust.rustcTarget}/lib/*.so $out/lib/
    runHook postInstall
  '';

  passthru = {
    targetPlatforms = platforms;
    targetPlatformsWithHostTools = platforms;
    badTargetPlatforms = [ ];
    unwrapped = finalAttrs.finalPackage;
  };

  meta = {
    inherit (finalAttrs.src.meta) homepage;
    description = "Minimal build of Rust";
    longDescription = ''
      A minimal build of Rust, built from source using mrustc.
      This is useful for bootstrapping the main Rust compiler without
      an initial binary toolchain download.
    '';
    maintainers = with lib.maintainers; [
      progval
      r-burns
    ];
    license = with lib.licenses; [
      mit
      asl20
    ];
    inherit platforms;
  };
})
