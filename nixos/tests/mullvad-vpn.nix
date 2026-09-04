{ lib, pkgs, ... }:
let
  resourceDir = "${pkgs.mullvad}/share/mullvad";
in
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

  testScript = ''
    machine.start()
    machine.wait_for_unit("mullvad-daemon.service")

    machine.succeed(
        "test -s '${resourceDir}/relays.json'",
        "test -s '${resourceDir}/ca.crt'",
        "pid=$(systemctl show mullvad-daemon.service --property=MainPID --value); "
        "tr '\\0' '\\n' < /proc/$pid/environ | "
        "grep -Fx 'MULLVAD_RESOURCE_DIR=${resourceDir}'",
    )
    machine.succeed("mullvad status")
    journal = machine.succeed("journalctl -u mullvad-daemon.service")
    assert "Failed to load bundled relays" not in journal
  '';
}
