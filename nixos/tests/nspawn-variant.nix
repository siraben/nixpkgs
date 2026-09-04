{ pkgs, ... }:
let
  evalConfig = import ../lib/eval-config.nix;

  nixos = evalConfig {
    system = null;
    modules = [
      {
        system.stateVersion = "26.05";
        nixpkgs.hostPlatform = pkgs.stdenv.hostPlatform.system;

        networking.hostName = "host";
        specialisation.rescue.configuration.environment.variables.RESCUE = "1";

        virtualisation.nspawnVariant.networking.hostName = pkgs.lib.mkForce "nspawn";
      }
    ];
  };
in
assert nixos.config.networking.hostName == "host";
assert nixos.config.virtualisation.nspawnVariant.networking.hostName == "nspawn";
assert builtins.hasAttr "rescue" nixos.config.specialisation;
assert nixos.config.virtualisation.nspawnVariant.specialisation == { };
pkgs.symlinkJoin {
  name = "nixos-test-nspawn-variant";
  paths = [ nixos.config.system.build.nspawn ];
}
