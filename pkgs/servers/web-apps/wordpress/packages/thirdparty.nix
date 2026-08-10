{
  fetchzip,
  stdenv,
  lib,
}:
{
  plugins.civicrm = stdenv.mkDerivation (finalAttrs: {
    pname = "civicrm";
    version = "6.2.0";
    src = fetchzip {
      inherit (finalAttrs) version;
      name = "civicrm";
      url = "https://download.civicrm.org/civicrm-${finalAttrs.version}-wordpress.zip";
      hash = "sha256-Bx1rixRbqJsiMrIIkzTGeqLIc5raiNoUVTsoxZ6q9uU=";
    };
    installPhase = ''
      runHook preInstall
      cp -r ./ -T $out
      runHook postInstall
    '';
    meta.license = lib.licenses.agpl3Only;
  });
  themes = {
    proton = stdenv.mkDerivation (finalAttrs: {
      pname = "proton";
      version = "1.0.1";
      src = fetchzip {
        inherit (finalAttrs) version;
        name = "proton";
        url = "https://github.com/christophery/proton/archive/refs/tags/${finalAttrs.version}.zip";
        hash = "sha256-JgKyLJ3dRqh1uwlsNuffCOM7LPBigGkLVFqftjFAiP4=";
      };
      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r ./* $out/
        runHook postInstall
      '';
      meta.license = lib.licenses.mit;
    });
  };
}
