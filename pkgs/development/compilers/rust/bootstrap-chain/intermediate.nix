{
  version,
  src,
  # Tools to install after build. `cargo` is needed for the *next* hop's
  # stage0 — but cargo 1.90.0 from `mrustc-bootstrap` drives every hop
  # via `--skip-stage0-validation`, so intermediate hops can pass `[]`
  # and skip the cargo build entirely. The terminal hop passes
  # `["cargo" "rustdoc"]` to get a real `pkgs.cargo` and to satisfy
  # `wrapRustcWith`'s rustdoc shim.
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
  # Tolerate stray override args from callers that treat this derivation
  # as if it were the standard nixpkgs cargo (e.g. cargo-auditable does
  # `cargo.override { auditable = false; }`).
  ...
}:
let
  triple = stdenv.targetPlatform.rust.rustcTargetSpec;

  # Hand-write bootstrap.toml: `pkgs.formats.toml` pulls in remarshal
  # and the entire Python test ecosystem (matplotlib, ffmpeg, …) just
  # to convert a Nix attrset to TOML.
  bootstrapToml = writeText "bootstrap.toml" ''
    change-id = "ignore"

    [llvm]
    link-shared = true

    [build]
    # Only build through stage1: stage2 (rustc N rebuilding itself) is
    # what the standard nixpkgs `rustc.nix` does for `pkgs.rustc`. The
    # chain just needs a working rustc + std + (optionally) cargo to
    # feed the next hop.
    build-stage = 1
    install-stage = 1

    build = "${triple}"
    host = ["${triple}"]
    target = ["${triple}"]

    cargo = "${lib.getExe' cargo "cargo"}"
    rustc = "${lib.getExe' rustc "rustc"}"

    docs = false
    extended = true
    tools = [${lib.concatMapStringsSep ", " (t: "\"${t}\"") tools}]
    # Stable channel default forces a profile-guided rebuild of LLVM
    # `compiler-builtins`. We don't need optimised intrinsics in a
    # throwaway chain compiler.
    optimized-compiler-builtins = false

    [install]
    sysconfdir = "etc"

    [rust]
    channel = "stable"
    llvm-bitcode-linker = false
    # Skip building the bundled lld and the llvm-tools-preview
    # component (llvm-objdump etc.). Nothing in the chain or in
    # `pkgs.rustc`'s wrapper invokes them.
    lld = false
    llvm-tools = false
    lto = "off"
    optimize = 2
    codegen-tests = false
    optimize-tests = false
    # Default 16; bumping splits each crate into more parallel codegen
    # jobs. Slightly less inlining, but the chain output rustc only
    # ever compiles the next hop once.
    codegen-units = 256
    codegen-units-std = 256

    [target.${triple}]
    llvm-config = "${lib.getExe' llvmShared.dev "llvm-config"}"
  '';

  # `--skip-stage0-validation` disables x.py's "stage0 cargo must be
  # within minor-1 of source version" guard. We always pass cargo
  # 1.90.0 from `mrustc-bootstrap`, even when source is rustc 1.92+.
  # cargo's rustc-driver protocol is stable enough across these
  # releases that cargo 1.90 successfully drives every hop — the
  # check is more conservative than reality.
  xpyFlags = [
    "--skip-stage0-validation"
    ''--set=build.jobs="$NIX_BUILD_CORES"''
  ];
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
    # Build rustc + tools explicitly so x.py install doesn't serialize
    # them behind the install copy step.
    python ./x.py build library rustc ${lib.concatStringsSep " " tools} \
      ${lib.concatStringsSep " " xpyFlags}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    python ./x.py install \
      ${lib.concatStringsSep " " xpyFlags} \
      --set=install.prefix="$out"
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
    # rustc.nix consumers reach for `rustc.unwrapped`; the chain
    # output IS the unwrapped rustc, so point it at itself.
    unwrapped = finalAttrs.finalPackage;
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
