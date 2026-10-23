{
  git,
  stdenv,
  buildPackages,
  curl,
  curlMinimal,
  ...
}@args:
git.override (
  {
    withManual = false;
    osxkeychainSupport = false;
    pythonSupport = false;
    perlSupport = false;
    withpcre2 = false;
    # override loses splicing, so select the runnable Cargo before overriding it.
    # Disabling auditing breaks cargo-auditable -> fetch-cargo-vendor ->
    # nix-prefetch-git -> gitMinimal -> cargo.
    cargo = buildPackages.cargo.override { auditable = false; };
    curl = if stdenv.hostPlatform.isFreeBSD then curlMinimal else curl; # Needed for FreeBSD bootstrap
  }
  // removeAttrs args [
    "git"
    "buildPackages"
    "curl"
    "curlMinimal"
  ]
)
