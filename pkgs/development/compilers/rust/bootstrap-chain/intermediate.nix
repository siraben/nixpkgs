{ version, src }:
{
  lib,
  stdenv,
  writeText,
  pkg-config,
  python3Minimal,
  cargo,
  rustc,
  llvmSharedForBuild,
  llvmSharedForHost,
  llvmSharedForTarget,
  libgit2,
  openssl,
  sqlite,
  # Tolerate stray override args from callers that treat this derivation
  # as if it were the standard nixpkgs cargo (e.g. cargo-auditable does
  # `cargo.override { auditable = false; }`). The chain's "cargo" output
  # is just a stage1 cargo binary in $out/bin/cargo — there's no
  # auditing wrapper to enable here.
  ...
}:
let
  buildTriple = stdenv.buildPlatform.rust.rustcTargetSpec;
  hostTriple = stdenv.hostPlatform.rust.rustcTargetSpec;
  targetTriple = stdenv.targetPlatform.rust.rustcTargetSpec;

  # When build/host/target are the same triple (the common native case)
  # we'd otherwise emit three [target."<triple>"] sections, which TOML
  # rejects. Build a {triple -> llvm-config} map and emit one section
  # per unique triple.
  llvmConfigByTriple =
    {
      ${buildTriple} = lib.getExe' llvmSharedForBuild.dev "llvm-config";
    }
    // {
      ${hostTriple} = lib.getExe' llvmSharedForHost.dev "llvm-config";
    }
    // {
      ${targetTriple} = lib.getExe' llvmSharedForTarget.dev "llvm-config";
    };
  targetSections = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (triple: llvmConfig: ''
      [target.${triple}]
      llvm-config = "${llvmConfig}"
    '') llvmConfigByTriple
  );

  # Hand-write bootstrap.toml instead of going through pkgs.formats.toml,
  # which pulls in remarshal -> the entire Python test ecosystem
  # (matplotlib, ffmpeg, …) just to convert a Nix attrset to TOML.
  bootstrapToml = writeText "bootstrap.toml" ''
    change-id = "ignore"

    [llvm]
    link-shared = true

    [build]
    # Only build through stage1: stage0 N-1 builds rustc N's compiler
    # crates and stdlib. Stage2 (rustc N rebuilding itself) is what the
    # user-facing rustc package does, and its doc lints can be finicky
    # for cross targets — chain hops just need to produce a working
    # rustc + std + cargo to feed the next hop.
    build-stage = 1
    install-stage = 1

    build = "${buildTriple}"
    host = ["${hostTriple}"]
    target = ["${targetTriple}"]

    cargo = "${lib.getExe' cargo "cargo"}"
    rustc = "${lib.getExe' rustc "rustc"}"

    docs = false
    extended = true
    tools = ["cargo"]

    [install]
    sysconfdir = "etc"

    [rust]
    channel = "stable"
    llvm-bitcode-linker = false
    lto = "off"
    optimize = 2

    ${targetSections}
  '';
in
stdenv.mkDerivation (finalAttrs: {
  inherit version src;
  pname = "rustc-bootstrap";

  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
    python3Minimal
  ];

  buildInputs = [
    libgit2
    openssl
    sqlite
  ];

  outputs = [
    "out"
    "man"
  ];

  configurePhase = ''
    runHook preConfigure
    ln -s ${bootstrapToml} bootstrap.toml
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    python ./x.py build library cargo \
      --set=build.jobs="$NIX_BUILD_CORES"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    python ./x.py install \
      --set build.jobs="$NIX_BUILD_CORES" \
      --set install.prefix="$out"
    runHook postInstall
  '';

  env = {
    LIBGIT2_NO_VENDOR = true;
    LIBSQLITE3_SYS_USE_PKG_CONFIG = true;
    OPENSSL_NO_VENDOR = true;
  };

  passthru = {
    targetPlatforms = [ "x86_64-linux" ];
    targetPlatformsWithHostTools = [ "x86_64-linux" ];
    badTargetPlatforms = [ ];
  };

  meta = {
    homepage = "https://www.rust-lang.org/";
    description = "Stage1 rustc + cargo for source-bootstrap chain (no docs, no stage2)";
    license = with lib.licenses; [
      mit
      asl20
    ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "rustc";
  };
})
