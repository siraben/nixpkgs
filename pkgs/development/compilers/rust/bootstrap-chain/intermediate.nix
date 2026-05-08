# Stage1-only rustc + (optionally) tools, intended as one hop in
# `bootstrap-chain/default.nix`. Not for direct consumption.
{
  version,
  src,
  tools,
}:
{
  lib,
  stdenv,
  writeText,
  pkg-config,
  python3Minimal,
  cargo,
  rustc,
  llvmShared,
  libgit2,
  openssl,
  sqlite,
  # Tolerate stray `cargo.override` args from callers that treat this
  # derivation as if it were the standard nixpkgs cargo (e.g.
  # cargo-auditable does `cargo.override { auditable = false; }`).
  ...
}:
let
  triple = stdenv.targetPlatform.rust.rustcTargetSpec;
  platforms = [ "x86_64-linux" ];

  # Hand-written bootstrap.toml; `pkgs.formats.toml` would pull in
  # remarshal -> matplotlib -> ffmpeg. Only flags that override an
  # upstream default appear here.
  bootstrapToml = writeText "bootstrap.toml" ''
    change-id = "ignore"

    [llvm]
    link-shared = true

    [build]
    build-stage = 1
    build = "${triple}"
    cargo = "${lib.getExe' cargo "cargo"}"
    rustc = "${lib.getExe' rustc "rustc"}"
    docs = false
    extended = true
    tools = [${lib.concatMapStringsSep ", " (t: "\"${t}\"") tools}]
    optimized-compiler-builtins = false

    [rust]
    channel = "stable"
    lld = false
    llvm-tools = false
    lto = "off"
    optimize = 2
    codegen-tests = false
    optimize-tests = false
    strip = true

    [target.${triple}]
    llvm-config = "${lib.getExe' llvmShared.dev "llvm-config"}"
  '';
in
stdenv.mkDerivation (finalAttrs: {
  pname = "rustc-bootstrap";
  inherit version src;

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

  configurePhase = ''
    runHook preConfigure
    ln -s ${bootstrapToml} bootstrap.toml
    runHook postConfigure
  '';

  # `--skip-stage0-validation` lets the chain reuse cargo 1.90 from
  # mrustc-bootstrap against rustc 1.92+ source; cargo's rustc-driver
  # protocol is stable enough across minors that x.py's
  # within-one-minor guard is over-conservative for our case.
  buildPhase = ''
    runHook preBuild
    python ./x.py build library rustc ${lib.concatStringsSep " " tools} \
      --skip-stage0-validation \
      --set=build.jobs="$NIX_BUILD_CORES"
    runHook postBuild
  '';

  # Bypass `python ./x.py install`: it spends ~30-50 s/hop building
  # rust-installer + generate-copyright and re-cp-ing through a tarball
  # staging area. Copy the stage1 outputs directly.
  installPhase = ''
    runHook preInstall
    stage1=build/${triple}/stage1
    mkdir -p $out/bin $out/lib

    install -m755 $stage1/bin/rustc $out/bin/rustc
    cp -P $stage1/lib/librustc_driver-*.so $out/lib/

    # 1.91 ships a separate top-level libstd.so; 1.92+ static-link it.
    cp -P $stage1/lib/libstd*.so $out/lib/ 2>/dev/null || true

    cp -rP $stage1/lib/rustlib $out/lib/
    # rustlib/{src,rustc-src} are symlinks back into /build.
    rm -rf $out/lib/rustlib/src $out/lib/rustlib/rustc-src

    # cargo lands in stage1-tools-bin, rustdoc in stage1/bin.
    for t in ${lib.concatStringsSep " " tools}; do
      for d in stage1-tools-bin stage1/bin; do
        if [ -e build/${triple}/$d/$t ]; then
          install -m755 build/${triple}/$d/$t $out/bin/$t
          break
        fi
      done
    done

    runHook postInstall
  '';

  env = {
    LIBGIT2_NO_VENDOR = true;
    LIBSQLITE3_SYS_USE_PKG_CONFIG = true;
    OPENSSL_NO_VENDOR = true;
  };

  passthru = {
    targetPlatforms = platforms;
    targetPlatformsWithHostTools = platforms;
    badTargetPlatforms = [ ];
    # rustc.nix consumers reach for `rustc.unwrapped`; the chain output
    # IS the unwrapped rustc, so point it at itself.
    unwrapped = finalAttrs.finalPackage;
  };

  meta = {
    homepage = "https://www.rust-lang.org/";
    description = "Stage1 rustc + cargo for source-bootstrap chain (no docs, no stage2)";
    license = with lib.licenses; [
      mit
      asl20
    ];
    inherit platforms;
    mainProgram = "rustc";
  };
})
