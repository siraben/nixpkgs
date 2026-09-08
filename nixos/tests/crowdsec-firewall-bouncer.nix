{ lib, pkgs, ... }:
let
  fakeBouncer = pkgs.writeShellApplication {
    name = "cs-firewall-bouncer";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      if [[ ! -e "$FIREWALL_READY_FILE" ]]; then
        echo "Firewall service has not finished starting" >&2
        exit 1
      fi

      for arg in "$@"; do
        if [[ "$arg" == "-t" ]]; then
          exit 0
        fi
      done

      systemd-notify --ready
      exec sleep infinity
    '';
  };

  mkNode =
    mode:
    let
      firewallService = if mode == "nftables" then "nftables" else "firewall";
      readyFile = "/run/${firewallService}-ready";
    in
    {
      networking.nftables.enable = mode == "nftables";

      services.crowdsec-firewall-bouncer = {
        enable = true;
        package = fakeBouncer;
        createRulesets = mode != "ipset";
        registerBouncer.enable = false;
        secrets.apiKeyPath = pkgs.writeText "api-key" "test-key";
        settings = {
          inherit mode;
          api_url = "http://127.0.0.1:8080";
        };
      };

      systemd.services = {
        ${firewallService} = {
          preStart = lib.mkBefore ''
            rm -f ${readyFile}
            sleep 1
          '';
          postStart = lib.mkAfter ''
            touch ${readyFile}
          '';
        };

        crowdsec-firewall-bouncer = {
          environment.FIREWALL_READY_FILE = readyFile;
          # The fake bouncer invokes systemd-notify as a child process.
          serviceConfig.NotifyAccess = "all";
        };
      };
    };
in
{
  name = "crowdsec-firewall-bouncer";
  meta.maintainers = with lib.maintainers; [
    nicomem
    tornax
  ];

  nodes = {
    nftables = mkNode "nftables";
    iptables = mkNode "iptables";
    ipset = mkNode "ipset";
  };

  testScript = ''
    start_all()

    def check_firewall_dependency(node, firewall_service):
        bouncer_service = "crowdsec-firewall-bouncer.service"

        node.wait_for_unit("multi-user.target")
        node.wait_for_unit(bouncer_service)

        for property_name in ["After", "Wants", "PartOf"]:
            units = node.succeed(
                f"systemctl show --property={property_name} --value {bouncer_service}"
            ).split()
            t.assertIn(firewall_service, units)

        invocation_id = node.succeed(
            f"systemctl show --property=InvocationID --value {bouncer_service}"
        ).strip()
        node.succeed(f"systemctl restart {firewall_service}")
        node.wait_for_unit(bouncer_service)
        new_invocation_id = node.succeed(
            f"systemctl show --property=InvocationID --value {bouncer_service}"
        ).strip()
        t.assertNotEqual(invocation_id, new_invocation_id)

    check_firewall_dependency(nftables, "nftables.service")
    check_firewall_dependency(iptables, "firewall.service")
    check_firewall_dependency(ipset, "firewall.service")
  '';
}
