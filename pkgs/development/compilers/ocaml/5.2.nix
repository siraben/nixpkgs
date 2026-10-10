import ./generic.nix {
  major_version = "5";
  minor_version = "2";
  patch_version = "1";
  # ocaml#13595 and its preceding x19 stack/register-allocation correction.
  patches = [ ./arm64-noalloc-stack-cfa.patch ];
  sha256 = "sha256-Bs2noj15wdOzazqnKDpe1YeY3dhx8sJpcSYR3Gn1c7I=";
}
