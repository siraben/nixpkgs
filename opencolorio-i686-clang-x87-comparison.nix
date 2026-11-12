# Compiler diagnostic only. No production defaults, tests or tolerances changed.
let
  pkgs = import /home/siraben/i686-iso-work/refresh-20261111/nixpkgs {
    system = "i686-linux";
  };
in
(pkgs.opencolorio.override {
  stdenv = pkgs.llvmPackages.stdenv;
}).overrideAttrs (old: {
  doCheck = true;
  cmakeFlags = old.cmakeFlags ++ [
    (pkgs.lib.cmakeBool "OCIO_USE_SIMD" false)
    (pkgs.lib.cmakeBool "CMAKE_EXPORT_COMPILE_COMMANDS" true)
  ];
  env = old.env // {
    # Clang otherwise defaults to Pentium 4 for this target. Forbid compiler
    # SSE/SSE2 too: this is a generic i686/x87 control, not another SSE2 trial.
    NIX_CFLAGS_COMPILE = (old.env.NIX_CFLAGS_COMPILE or "")
      + " -march=i686 -mno-sse -mno-sse2 -mfpmath=387";
  };
})
