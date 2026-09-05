{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "legba";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "evilsocket";
    repo = "legba";
    rev = finalAttrs.version;
    hash = "sha256-FrmPR9K/Ci+fm0IzmczgfRHVa1tYYNuaNnlfO9bQwDU=";
  };

  cargoHash = "sha256-G/O8no8yIYqpAhEA6r7qYckpTQb/PtV0U+Ysl5R/f9k=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  env.OPENSSL_NO_VENDOR = true;

  meta = {
    description = "Multiprotocol credentials bruteforcer / password sprayer and enumerator";
    homepage = "https://github.com/evilsocket/legba";
    changelog = "https://github.com/evilsocket/legba/releases/tag/${finalAttrs.version}";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ mikaelfangel ];
    mainProgram = "legba";
  };
})
