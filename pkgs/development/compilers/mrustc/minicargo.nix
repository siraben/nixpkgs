{
  lib,
  stdenv,
  makeWrapper,
  mrustc,
}:

stdenv.mkDerivation rec {
  pname = "mrustc-minicargo";
  inherit (mrustc) src version;

  strictDeps = true;
  nativeBuildInputs = [ makeWrapper ];

  enableParallelBuilding = true;
  makefile = "minicargo.mk";
  makeFlags = [ "bin/minicargo" ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp bin/minicargo $out/bin

    # Default MRUSTC_PATH to the bundled mrustc, but allow callers
    # (notably run_rustc, which invokes minicargo with the just-bootstrapped
    # rustc as MRUSTC_PATH) to override it.
    wrapProgram "$out/bin/minicargo" --set-default MRUSTC_PATH ${mrustc}/bin/mrustc
    runHook postInstall
  '';

  meta = {
    description = "Minimalist builder for Rust";
    mainProgram = "minicargo";
    longDescription = ''
      A minimalist builder for Rust, similar to Cargo but written in C++.
      Designed to work with mrustc to build Rust projects
      (like the Rust compiler itself).
    '';
    inherit (src.meta) homepage;
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      progval
      r-burns
    ];
    platforms = [ "x86_64-linux" ];
  };
}
