import ./generic.nix {
  major_version = "5";
  minor_version = "3";
  patch_version = "0";
  # ocaml#13595 and its preceding x19 stack/register-allocation correction.
  patches = [ ./arm64-noalloc-stack-cfa.patch ];
  sha256 = "sha256-sCKTNtnr4K+QWVS80a5bKTMGu8sIwB6tA1ANnlvJAWQ=";
}
