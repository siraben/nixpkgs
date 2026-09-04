{
  config,
  extendModules,
  lib,
  ...
}:
let
  nspawnVariant = extendModules {
    modules = [
      ./guest-networking-options.nix
      ./nspawn-container
      {
        specialisation = lib.mkForce { };
        virtualisation.vlans = lib.mkDefault [ ];
      }
    ];
  };
in
{
  options.virtualisation.nspawnVariant = lib.mkOption {
    description = ''
      Machine configuration to be added to the systemd-nspawn container
      launcher exposed as `system.build.nspawn`.
    '';
    inherit (nspawnVariant) type;
    default = { };
    visible = "shallow";
  };

  config = {
    system.build.nspawn = lib.mkDefault config.virtualisation.nspawnVariant.system.build.nspawn;

    virtualisation.nspawnVariant.options.virtualisation.nspawnVariant = lib.mkOption {
      apply = _: throw "virtualisation.nspawnVariant.virtualisation.nspawnVariant is not supported";
    };
  };

  # Uses extendModules.
  meta.buildDocsInSandbox = false;
}
