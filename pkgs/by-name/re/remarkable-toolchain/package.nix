{
  lib,
  stdenv,
  fetchurl,
  hello,
  runCommand,
  python3,
  file,
  which,
  xz,
  device ? "rm1",
}:

let
  osVersion = "3.27.0.97";
  sdkVersion = "5.7.119";

  devices = {
    rm1 = {
      productName = "reMarkable 1";
      target = "cortexa9hf-neon-remarkable-linux-gnueabi";
      elfPattern = "ELF 32-bit.* ARM, EABI5";
      hashes = {
        x86_64-linux = "sha256-287c7l2z4XxiskEyuDzUGOHwWQ4dnkMct4fPbnmKIc8=";
        aarch64-linux = "sha256-Ls9+LebmTKUJJS0uzcAPeBgRbbha9aEZLXrnB6wisbU=";
      };
    };
    rm2 = {
      productName = "reMarkable 2";
      target = "cortexa7hf-neon-remarkable-linux-gnueabi";
      elfPattern = "ELF 32-bit.* ARM, EABI5";
      hashes = {
        x86_64-linux = "sha256-esdNr4F+ydDFK8rsnyOx0+xc9+WkH1jh1zn7VPv5R9Q=";
        aarch64-linux = "sha256-E0lBbGT9xMzXFylgS1e2Ss9zKaF5qC3XaKPk2iq5prc=";
      };
    };
    ferrari = {
      productName = "reMarkable Paper Pro";
      target = "cortexa53-crypto-remarkable-linux";
      elfPattern = "ELF 64-bit.* ARM aarch64";
      hashes = {
        x86_64-linux = "sha256-Mk132E3aW6j6xIQQezyZgdqqKP5evtZYkXLwyxvN0CA=";
        aarch64-linux = "sha256-IYhHEHufynv/j7ktsB71907D3yg6n/D+Om5itkqCN7Q=";
      };
    };
    chiappa = {
      productName = "reMarkable Paper Pro Move";
      target = "cortexa55-remarkable-linux";
      elfPattern = "ELF 64-bit.* ARM aarch64";
      hashes = {
        x86_64-linux = "sha256-8ieUvGu2cp5kinQEpWHocNU3gYvWKi+ZUFIvDPFbQTA=";
        aarch64-linux = "sha256-1uZRL4EtHhyPch/hzOlX/sRhQ0/TvQTOUP9v3VdE4f8=";
      };
    };
    tatsu = {
      productName = "reMarkable Paper Pure";
      target = "cortexa55-remarkable-linux";
      elfPattern = "ELF 64-bit.* ARM aarch64";
      hashes = {
        x86_64-linux = "sha256-Fl2fCQqL7OLo32la22Bs1xRsG3Zpm+PVMMDyMQUmTdU=";
        aarch64-linux = "sha256-+xeNDtlpcCofOG95ePdmhVwXPhgXUHMQZjBFuZ0OLIY=";
      };
    };
  };

  deviceInfo =
    devices.${device}
      or (throw "remarkable-toolchain: unsupported device ${lib.escapeShellArg device}");

  hostArchitectures = {
    x86_64-linux = "x86_64";
    aarch64-linux = "aarch64";
  };
  hostSystem = stdenv.hostPlatform.system;
  hostArchitecture =
    hostArchitectures.${hostSystem}
      or (throw "remarkable-toolchain: unsupported host platform ${hostSystem}");
in
stdenv.mkDerivation (finalAttrs: {
  pname = "remarkable-sdk-${device}";
  version = sdkVersion;

  src = fetchurl {
    url = "https://storage.googleapis.com/remarkable-codex-toolchain/${osVersion}/${device}/remarkable-production-image-${finalAttrs.version}-${device}-public-${hostArchitecture}-toolchain.sh";
    hash = deviceInfo.hashes.${hostSystem};
  };

  nativeBuildInputs = [
    file
    python3
    which
    xz
  ];

  dontUnpack = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    markerLine=$(grep -na -m1 '^MARKER:$' "$src" | cut -d: -f1)
    head -n "$((markerLine - 1))" "$src" > sdk-installer
    substituteInPlace sdk-installer \
      --replace-fail \
        'post_relocate="$target_sdk_dir/post-relocate-setup.sh"' \
        'find "$target_sdk_dir" -path "*/post-relocate-setup.d/*" -type f -exec sed -i "1s|^#!/usr/bin/env python3$|#!${python3}/bin/python3|" {} +
    post_relocate="$target_sdk_dir/post-relocate-setup.sh"'
    tail -n +"$markerLine" "$src" >> sdk-installer

    mkdir -p $out
    ENVCLEANED=1 sh sdk-installer -y -d $out

    runHook postInstall
  '';

  passthru = {
    inherit
      device
      hostArchitecture
      osVersion
      ;
    inherit (deviceInfo) productName target;
    supportedDevices = lib.mapAttrs (
      _: info:
      removeAttrs info [
        "hashes"
        "elfPattern"
      ]
    ) devices;
    tests.gnuHello = runCommand "remarkable-sdk-${device}-gnu-hello" { } ''
      tar xf ${hello.src}
      cd hello-*
      source ${finalAttrs.finalPackage}/environment-setup-${deviceInfo.target}
      ./configure $CONFIGURE_FLAGS
      make -j"$NIX_BUILD_CORES"

      mkdir -p "$out/bin"
      cp hello "$out/bin/"
      ${lib.getExe file} "$out/bin/hello" | tee "$out/elf-info"
      grep -Eq ${lib.escapeShellArg deviceInfo.elfPattern} "$out/elf-info"
    '';
  };

  meta = {
    description = "Official SDK for ${deviceInfo.productName} running reMarkable OS ${osVersion}";
    homepage = "https://developer.remarkable.com/documentation/sdk";
    downloadPage = "https://developer.remarkable.com/links";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    # This is an aggregate Yocto SDK; its components retain their individual
    # free software licenses under the sysroots.
    license = lib.licenses.free;
    maintainers = with lib.maintainers; [ siraben ];
    platforms = builtins.attrNames hostArchitectures;
  };
})
