# Shared passthru and targetPrefix for cosmocc cc wrappers.
{ lib, stdenv }:

{
  targetPrefix = lib.optionalString (
    stdenv.hostPlatform != stdenv.targetPlatform
  ) "${stdenv.targetPlatform.config}-";

  passthru = {
    isCosmopolitan = true;
    isGNU = false;
    isClang = false;
    hardeningUnsupportedFlagsByTargetPlatform = _: [
      "bindnow"
      "relro"
      "pic"
      "pie"
      "fortify"
      "fortify3"
      "stackclashprotection"
      "stackprotector"
      "zerocallusedregs"
    ];
  };
}
