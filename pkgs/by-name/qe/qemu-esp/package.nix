{
  lib,
  qemu,
  fetchFromGitHub,
  cacert,
  git,
  libgcrypt,
  meson,
}:

# Espressif's QEMU fork: adds the esp32 / esp32s3 machine types and
# LX6 / LX7 cores that mainline qemu-system-xtensa lacks.
(qemu.override {
  hostCpuTargets = [ "xtensa-softmmu" ];
  minimal = true;
}).overrideAttrs
  (old: {
    pname = "qemu-esp";
    version = "9.2.2-esp-20260417";

    src = fetchFromGitHub {
      owner = "espressif";
      repo = "qemu";
      tag = "esp-develop-9.2.2-20260417";
      hash = "sha256-bFxVhMg4ogyUEqtzNDm7mK4QK0w1cIzHteGzKebubwg=";
      # Pre-fetch the meson wrap subprojects; the qemu build is offline.
      nativeBuildInputs = [
        cacert
        git
        meson
      ];
      postFetch = ''
        (
          cd "$out"
          for prj in subprojects/*.wrap; do
            meson subprojects download "$(basename "$prj" .wrap)"
            rm -rf subprojects/$(basename "$prj" .wrap)/.git
          done
        )
      '';
    };

    configureFlags = (old.configureFlags or [ ]) ++ [
      "--enable-gcrypt"
      "--enable-slirp"
    ];

    buildInputs = (old.buildInputs or [ ]) ++ [ libgcrypt ];

    # The mainline package's passthru contains an incompatible updater,
    # qemu-system-i386 path, and tests for targets this build does not include.
    passthru = { };

    meta = old.meta // {
      description = "Espressif's QEMU fork with ESP32 and ESP32-S3 machine emulation";
      homepage = "https://github.com/espressif/qemu";
      mainProgram = "qemu-system-xtensa";
      maintainers = with lib.maintainers; [ siraben ];
    };
  })
