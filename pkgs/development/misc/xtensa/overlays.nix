{
  fetchFromGitHub,
}:

# Espressif's MIT-licensed per-chip Xtensa configuration data
# (XCHAL_* macros); no Espressif toolchain patches are applied.
fetchFromGitHub {
  owner = "espressif";
  repo = "xtensa-overlays";
  rev = "dd1cf19f6eb327a9db51043439974a6de13f5c7f";
  hash = "sha256-guFWS6QAjJ1Z2u2YOIha97EaBGLThWRz6kjrPSf0y9M=";
}
