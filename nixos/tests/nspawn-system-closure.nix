{ pkgs, lib, ... }:
let
  nspawnConfiguration =
    (import ../lib/eval-config.nix {
      system = null;
      modules = [
        (
          { config, lib, ... }:
          {
            imports = [ ../modules/profiles/minimal.nix ];

            nixpkgs.pkgs = pkgs;
            networking.hostName = "host-configuration";
            system.stateVersion = config.system.nixos.release;

            virtualisation.nspawnVariant = {
              networking.hostName = lib.mkForce "nspawn-closure";
              virtualisation.rootDir = "/var/lib/nspawn-closure-root";

              systemd.services.nspawn-closure-initialized = {
                wantedBy = [ "multi-user.target" ];
                after = [ "nixos-activation.service" ];
                serviceConfig.Type = "oneshot";
                script = ''
                  . /etc/os-release
                  printf 'system=%s\nid=%s\nhostname=%s\n' \
                    "$(${pkgs.coreutils}/bin/readlink -f /run/current-system)" \
                    "$ID" \
                    "$(cat /etc/hostname)" > /initialized
                '';
              };
            };
          }
        )
      ];
    }).config;

  nspawnLauncher = nspawnConfiguration.system.build.nspawn;
  nspawnSystem = nspawnConfiguration.virtualisation.nspawnVariant.system.build.toplevel;
in
assert nspawnConfiguration.networking.hostName == "host-configuration";
{
  name = "nspawn-system-closure";

  nodes.machine = {
    imports = [ ../modules/profiles/minimal.nix ];
    virtualisation.additionalPaths = [
      nspawnLauncher
      nspawnSystem
    ];
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    machine.succeed("${lib.getExe' pkgs.systemd "systemd-nspawn"} --version | grep -F '${pkgs.systemd.version}'")
    machine.succeed("test -L ${nspawnSystem}/etc")
    machine.succeed("readlink ${nspawnSystem}/etc | grep -E '^/nix/store/.+-etc/etc$'")
    machine.fail("test -e ${nspawnSystem}/nix/store")

    with subtest("raw boot mode rejects a system closure"):
        machine.fail(
            "${lib.getExe' pkgs.systemd "systemd-nspawn"} --quiet --read-only "
            "--private-users=no --register=no --boot --directory=${nspawnSystem} "
            ">/tmp/raw-nspawn.log 2>&1"
        )
        machine.succeed("grep -F 'os-release file is missing' /tmp/raw-nspawn.log")

    with subtest("the first-class launcher initializes the intended closure"):
        machine.succeed(
            "systemd-run --unit=nspawn-closure --property=Type=exec "
            "${lib.getExe nspawnLauncher}"
        )
        machine.wait_until_succeeds("test -s /var/lib/nspawn-closure-root/initialized")
        machine.succeed("grep -Fx 'system=${nspawnSystem}' /var/lib/nspawn-closure-root/initialized")
        machine.succeed("grep -Fx 'id=nixos' /var/lib/nspawn-closure-root/initialized")
        machine.succeed("grep -Fx 'hostname=nspawn-closure' /var/lib/nspawn-closure-root/initialized")
        machine.succeed("systemctl stop nspawn-closure.service")
        machine.wait_until_succeeds("test $(systemctl is-active nspawn-closure.service) = inactive")
  '';
}
