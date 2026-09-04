{ lib, ... }:

{
  name = "mullvad-vpn";

  meta.maintainers = with lib.maintainers; [
    arcuru
    jackr
    sigmasquadron
  ];

  nodes.machine = {
    virtualisation.restrictNetwork = true;

    services.mullvad-vpn = {
      enable = true;
      enableExcludeWrapper = false;
    };
  };

  testScript =
    { nodes, ... }:
    let
      resourceDir = nodes.machine.services.mullvad-vpn.package.mullvadResourceDir;
    in
    ''
      import json

      start_all()
      machine.wait_for_unit("mullvad-daemon.service")

      with subtest("bundled daemon resources exist"):
          relays = json.loads(machine.succeed("cat '${resourceDir}/relays.json'"))
          assert len(relays["wireguard"]["relays"]) > 0
          machine.succeed(
              "grep -qF -- '-----BEGIN CERTIFICATE-----' '${resourceDir}/ca.crt'"
          )

      with subtest("service exposes the resource directory"):
          expected = "MULLVAD_RESOURCE_DIR=${resourceDir}"
          environment = machine.succeed(
              "systemctl show mullvad-daemon.service --property=Environment --value"
          ).split()
          assert expected in environment, environment

          pid = machine.succeed(
              "systemctl show mullvad-daemon.service --property=MainPID --value"
          ).strip()
          assert pid != "0"
          environment = machine.succeed(
              f"tr '\\0' '\\n' < /proc/{pid}/environ"
          ).splitlines()
          assert expected in environment, environment

      with subtest("daemon starts without credentials or network access"):
          machine.wait_until_succeeds("mullvad status")
          machine.succeed("systemctl is-active --quiet mullvad-daemon.service")
          journal = machine.succeed("journalctl -u mullvad-daemon.service")
          assert "Failed to load bundled relays" not in journal
    '';
}
