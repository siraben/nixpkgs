{
  lib,
  stdenv,
  fetchurl,
  writeText,
}:

import ./versions.nix (
  { version, hash, ... }:
  stdenv.mkDerivation (finalAttrs: {
    pname = "zabbix-web";
    inherit version;

    src = fetchurl {
      url = "https://cdn.zabbix.com/zabbix/sources/stable/${lib.versions.majorMinor finalAttrs.version}/zabbix-${finalAttrs.version}.tar.gz";
      inherit hash;
    };

    phpConfig = writeText "zabbix.conf.php" ''
      <?php
        return require(getenv('ZABBIX_CONFIG'));
      ?>
    '';

    installPhase = ''
      mkdir -p $out/share/zabbix/
      cp -a ui/. $out/share/zabbix/
      cp ${finalAttrs.phpConfig} $out/share/zabbix/conf/zabbix.conf.php
    '';

    meta = {
      description = "Enterprise-class open source distributed monitoring solution (web frontend)";
      homepage = "https://www.zabbix.com/";
      license =
        if (lib.versions.major finalAttrs.version >= "7") then
          lib.licenses.agpl3Only
        else
          lib.licenses.gpl2Plus;
      maintainers = with lib.maintainers; [
        bstanderline
        mmahut
      ];
      platforms = lib.platforms.linux;
    };
  })
)
