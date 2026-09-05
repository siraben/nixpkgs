{
  lib,
  stdenv,
  fetchFromGitHub,
  clang-tools,
  installShellFiles,
  ninja,
  pkg-config,
  rustPlatform,
  zlib,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "cabinpkg";
  version = "0.17.0";

  src = fetchFromGitHub {
    owner = "cabinpkg";
    repo = "cabin";
    tag = finalAttrs.version;
    hash = "sha256-YJ5wGtidhwi6o02l+p/+TzWY0s0IxJx5V7ECtptQwsY=";
  };

  cargoHash = "sha256-mSG4Pf8oFhfQ+kdWwJj77zNfRaW3l2ijXVuaHeyL5DI=";

  patches = [ ./limit-builtin-exclusions-to-project.patch ];

  nativeBuildInputs = [ installShellFiles ];

  nativeCheckInputs = [
    clang-tools
    ninja
    pkg-config
  ];

  checkInputs = [ zlib ];

  cargoTestFlags = [
    "--workspace"
    "--all-targets"
    "--all-features"
  ];

  # nixpkgs' clang-tools does not include LLVM's run-clang-tidy.py script.
  checkFlags = [ "--skip=external_tool_smoke::cabin_tidy_reaches_real_tidy" ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd cabin \
      --bash <($out/bin/cabin compgen bash) \
      --fish <($out/bin/cabin compgen fish) \
      --zsh <($out/bin/cabin compgen zsh)

    $out/bin/cabin mangen --output-dir man
    installManPage man/*.1
  '';

  meta = {
    homepage = "https://cabinpkg.com";
    changelog = "https://github.com/cabinpkg/cabin/releases/tag/${finalAttrs.version}";
    description = "Package manager and build system for C++";
    license = lib.licenses.asl20;
    maintainers = [ ];
    platforms = lib.platforms.unix;
    mainProgram = "cabin";
  };
})
