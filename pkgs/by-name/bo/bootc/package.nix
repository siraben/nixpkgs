{
  lib,
  rustPlatform,
  fetchFromGitHub,
  libselinux,
  libz,
  zstd,
  pkg-config,
  openssl,
  glib,
  ostree-full,
  versionCheckHook,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "bootc";
  version = "1.16.11";

  cargoHash = "sha256-YiUC9fL11FA/527Lfp6N6gvNyJY1m+sdygbtndgcdVI=";

  env.SELINUX_LIB_DIR = "${lib.getLib libselinux}/lib";

  doInstallCheck = true;

  src = fetchFromGitHub {
    owner = "bootc-dev";
    repo = "bootc";
    rev = "v${finalAttrs.version}";
    hash = "sha256-k8FwFxisFpFUdiKild1i8Ool2G3pLiyDRbhp89JAW0U=";
  };

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    libselinux
    libz
    zstd
    openssl
    glib
    ostree-full
  ];

  checkFlags = [
    # These all require a writable /var/tmp
    "--skip=test_cli_fns"
    "--skip=test_diff"
    "--skip=test_tar_export_reproducible"
    "--skip=test_tar_export_structure"
    "--skip=test_tar_import_empty"
    "--skip=test_tar_import_export"
    "--skip=test_tar_import_signed"
    "--skip=test_tar_write"
    "--skip=test_tar_write_tar_layer"
  ];

  cargoBuildFlags = [ "-p bootc" ];

  nativeInstallCheckInputs = [
    versionCheckHook
  ];

  meta = {
    description = "Boot and upgrade via container images";
    homepage = "https://bootc-dev.github.io/bootc";
    license = lib.licenses.mit;
    mainProgram = "bootc";
    maintainers = with lib.maintainers; [ thesola10 ];
    platforms = lib.platforms.linux;
  };
})
