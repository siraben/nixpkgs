{ lib, ... }:
{
  name = "tailscale";

  meta.maintainers = with lib.maintainers; [
    mbaillie
    mfrw
  ];

  nodes.machine =
    { lib, pkgs, ... }:
    {
      services.tailscale.enable = true;
      networking.networkmanager.enable = true;

      systemd.services = {
        # Keep the transaction deterministic while retaining tailscaled's
        # NetworkManager-specific ordering edge.
        NetworkManager-wait-online.enable = lib.mkForce false;

        # Start tailscaled explicitly after normalizing the target state below.
        tailscaled = {
          wantedBy = lib.mkForce [ ];
          serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/touch /run/tailscaled-started";
        };

        # Record when network-online.target pulls in its provider, then block the
        # target so the test can observe tailscaled's ordering constraint.
        network-online-blocker = {
          wantedBy = [ "network-online.target" ];
          before = [ "network-online.target" ];
          serviceConfig.Type = "oneshot";
          script = ''
            touch /run/network-online-blocker-started
            while [[ ! -e /run/network-online-ready ]]; do
              sleep 0.1
            done
          '';
        };
      };
    };

  testScript = ''
    start_all()

    machine.succeed(
        "systemctl stop tailscaled.service network-online.target network-online-blocker.service"
    )
    machine.succeed(
        "rm -f /run/tailscaled-started "
        "/run/network-online-blocker-started /run/network-online-ready"
    )

    machine.succeed("systemctl start --no-block tailscaled.service")
    machine.wait_until_succeeds(
        "test -e /run/network-online-blocker-started || test -e /run/tailscaled-started"
    )

    # Starting tailscaled must pull the online barrier into the transaction.
    machine.succeed("test -e /run/network-online-blocker-started")

    # tailscaled must remain queued until network-online.target is reached.
    machine.fail("test -e /run/tailscaled-started")
    machine.succeed("systemctl list-jobs --no-legend | grep -F 'network-online.target'")
    machine.succeed("systemctl list-jobs --no-legend | grep -F 'tailscaled.service'")

    machine.succeed("touch /run/network-online-ready")
    machine.wait_for_unit("network-online.target")
    machine.wait_for_unit("tailscaled.service")
    machine.succeed("test -e /run/tailscaled-started")

    after = machine.succeed(
        "systemctl show tailscaled.service --property=After --value"
    ).split()
    assert "network-online.target" in after, after
    assert "NetworkManager-wait-online.service" in after, after

    wants = machine.succeed(
        "systemctl show tailscaled.service --property=Wants --value"
    ).split()
    assert "network-online.target" in wants, wants
  '';
}
