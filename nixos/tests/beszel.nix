{ pkgs, lib, ... }:
let
  perfEventProbe = pkgs.runCommandCC "perf-event-probe" { } ''
    mkdir -p $out/bin
    $CC -Wall -Werror -o $out/bin/perf-event-probe ${pkgs.writeText "perf-event-probe.c" ''
      #include <linux/perf_event.h>
      #include <stdio.h>
      #include <string.h>
      #include <sys/syscall.h>
      #include <unistd.h>

      int main(void) {
        struct perf_event_attr event;
        memset(&event, 0, sizeof(event));
        event.type = PERF_TYPE_SOFTWARE;
        event.size = sizeof(event);
        event.config = PERF_COUNT_SW_TASK_CLOCK;

        int fd = syscall(SYS_perf_event_open, &event, 0, -1, -1, 0);
        if (fd == -1) {
          perror("perf_event_open");
          return 1;
        }
        close(fd);
        puts("perf_event_open succeeded");
        return 0;
      }
    ''}
  '';

  probeAgent = pkgs.writeShellApplication {
    name = "beszel-agent";
    text = ''
      ${perfEventProbe}/bin/perf-event-probe
      exec ${pkgs.coreutils}/bin/sleep infinity
    '';
  };
in
{
  name = "beszel";
  meta.maintainers = with lib.maintainers; [ h7x4 ];

  nodes = {
    hubHost =
      { config, pkgs, ... }:
      {
        virtualisation.vlans = [ 1 ];

        systemd.network.networks."01-eth1" = {
          name = "eth1";
          networkConfig.Address = "10.0.0.1/24";
        };

        networking = {
          useNetworkd = true;
          useDHCP = false;
        };

        services.beszel.hub = {
          enable = true;
          host = "10.0.0.1";
        };

        networking.firewall.allowedTCPPorts = [
          config.services.beszel.hub.port
        ];

        environment.systemPackages = [
          config.services.beszel.hub.package
        ];
      };

    intelAgent = {
      boot.kernel.sysctl."kernel.perf_event_paranoid" = 4;
      services.beszel.agent = {
        enable = true;
        package = probeAgent;
        environment.GPU_COLLECTOR = "intel_gpu_top";
      };
    };

    agentHost =
      { config, pkgs, ... }:
      {
        virtualisation.vlans = [ 1 ];

        systemd.network.networks."01-eth1" = {
          name = "eth1";
          networkConfig.Address = "10.0.0.2/24";
        };

        networking = {
          useNetworkd = true;
          useDHCP = false;
        };

        environment.systemPackages = with pkgs; [ jq ];

        specialisation."agent".configuration = {
          services.beszel.agent = {
            enable = true;
            environment.HUB_URL = "http://10.0.0.1:8090";
            environment.KEY_FILE = "/var/lib/beszel-agent/id_ed25519.pub";
            environment.TOKEN_FILE = "/var/lib/beszel-agent/token";
            openFirewall = true;
          };
        };
      };
  };

  testScript =
    { nodes, ... }:
    let
      hubCfg = nodes.hubHost.services.beszel.hub;
      agentCfg = nodes.agentHost.specialisation."agent".configuration.services.beszel.agent;
    in
    ''
      import json
      from datetime import timedelta

      start_all()

      with subtest("Intel GPU collector service permissions"):
        intelAgent.execute("systemctl start beszel-agent.service")
        intelAgent.wait_until_succeeds(
          "journalctl -u beszel-agent.service --grep 'perf_event_open succeeded'",
          timeout=timedelta(seconds=30),
        )
        intelAgent.wait_for_unit("beszel-agent.service")
        assert "cap_perfmon" in intelAgent.succeed("systemctl show beszel-agent.service -p AmbientCapabilities --value").split()
        assert "cap_perfmon" in intelAgent.succeed("systemctl show beszel-agent.service -p CapabilityBoundingSet --value").split()
        assert intelAgent.succeed("systemctl show beszel-agent.service -p NoNewPrivileges --value").strip() == "yes"
        assert intelAgent.succeed("systemctl show beszel-agent.service -p PrivateDevices --value").strip() == "no"
        assert intelAgent.succeed("systemctl show beszel-agent.service -p PrivateUsers --value").strip() == "no"
        assert "perf_event_open" in intelAgent.succeed("systemctl show beszel-agent.service -p SystemCallFilter --value").split()

      with subtest("Start hub"):
        hubHost.wait_for_unit("beszel-hub.service")
        hubHost.wait_for_open_port(${toString hubCfg.port}, "${toString hubCfg.host}")

      with subtest("Register user"):
        agentHost.succeed('curl -f --json \'${
          builtins.toJSON {
            email = "admin@example.com";
            password = "password";
          }
        }\' "${agentCfg.environment.HUB_URL}/api/beszel/create-user"')
        user = json.loads(agentHost.succeed('curl -f --json \'${
          builtins.toJSON {
            identity = "admin@example.com";
            password = "password";
          }
        }\' ${agentCfg.environment.HUB_URL}/api/collections/users/auth-with-password').strip())

      with subtest("Install agent credentials"):
        agentHost.succeed("mkdir -p \"$(dirname '${agentCfg.environment.KEY_FILE}')\" \"$(dirname '${agentCfg.environment.TOKEN_FILE}')\"")
        sshkey = agentHost.succeed(f"curl -H 'Authorization: {user["token"]}' -f ${agentCfg.environment.HUB_URL}/api/beszel/getkey | jq -r .key").strip()
        utoken = agentHost.succeed(f"curl -H 'Authorization: {user["token"]}' -f ${agentCfg.environment.HUB_URL}/api/beszel/universal-token | jq -r .token").strip()
        agentHost.succeed(f"echo '{sshkey}' > '${agentCfg.environment.KEY_FILE}'")
        agentHost.succeed(f"echo '{utoken}' > '${agentCfg.environment.TOKEN_FILE}'")

      with subtest("Register agent in hub"):
        agentHost.succeed(f'curl -H \'Authorization: {user["token"]}\' -f --json \'{${
          builtins.toJSON {
            "host" = "10.0.0.2";
            "name" = "agent";
            "pkey" = "{sshkey}";
            "port" = "45876";
            "tkn" = "{utoken}";
            "users" = "{user['record']['id']}";
          }
        }}\' "${agentCfg.environment.HUB_URL}/api/collections/systems/records"')

      with subtest("Start agent"):
        agentHost.succeed("/run/current-system/specialisation/agent/bin/switch-to-configuration switch")
        agentHost.wait_for_unit("beszel-agent.service")
        agentHost.wait_until_succeeds("journalctl -eu beszel-agent --grep 'SSH connection established'")
        agentHost.wait_until_succeeds(f'curl -H \'Authorization: {user["token"]}\' -f ${agentCfg.environment.HUB_URL}/api/collections/systems/records | jq -e \'.items[].status == "up"\' ')
    '';
}
