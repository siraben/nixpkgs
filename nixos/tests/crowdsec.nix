{
  lib,
  pkgs,
  ...
}:
let
  offlineCscli = pkgs.writeShellScriptBin "cscli" ''
    if [[ "$#" -eq 3 && "$1" == -c=* && "$2" == hub && "$3" == update ]]; then
      echo "simulated offline hub update" >&2
      exit 1
    fi

    if [[ "$#" -ge 2 && "$1" == bouncers && "$2" == list ]]; then
      if [[ -e /var/lib/crowdsec-firewall-bouncer-register/api-key.cred ]]; then
        printf '[{"name":"crowdsec-firewall-bouncer"}]\n'
      else
        printf '[]\n'
      fi
      exit 0
    fi

    if [[ "$#" -ge 2 && "$1" == bouncers && "$2" == add ]]; then
      printf 'test-api-key\n'
      exit 0
    fi

    exec ${lib.getExe' pkgs.crowdsec "cscli"} "$@"
  '';

  crowdsec = pkgs.buildEnv {
    name = "crowdsec-offline-test";
    paths = [
      (lib.hiPrio offlineCscli)
      pkgs.crowdsec
    ];
  };
in
{
  name = "crowdsec";

  meta.maintainers = with lib.maintainers; [
    M0ustach3
    tornax
    jk
  ];

  nodes.machine = {
    services.crowdsec = {
      enable = true;
      package = crowdsec;
      localConfig.acquisitions = [
        {
          source = "file";
          filenames = [ "/var/log/crowdsec-test.log" ];
          labels.type = "syslog";
        }
      ];
      settings = {
        general.api.server.enable = true;
        lapi.credentialsFile = "/var/lib/crowdsec/state/local_api_credentials.yaml";
      };
    };

    services.crowdsec-firewall-bouncer.enable = true;

    # The registration unit is the subject of this test; avoid exercising the
    # firewall backend and its unrelated host firewall integration.
    systemd.services.crowdsec-firewall-bouncer.wantedBy = lib.mkForce [ ];

    systemd.tmpfiles.rules = [ "f /var/log/crowdsec-test.log 0640 crowdsec crowdsec -" ];
  };

  testScript = ''
    credentials = "/var/lib/crowdsec/state/local_api_credentials.yaml"
    api_key = "/var/lib/crowdsec-firewall-bouncer-register/api-key.cred"

    machine.wait_for_unit("crowdsec.service")
    machine.wait_for_open_port(8080)
    machine.wait_for_file(api_key)

    with subtest("offline hub update does not block startup"):
        machine.succeed(
            "journalctl -u crowdsec.service --no-pager | "
            "grep -F 'simulated offline hub update'"
        )
        machine.succeed(
            "journalctl -u crowdsec.service --no-pager | "
            "grep -F 'warning: unable to update the hub index; continuing with local hub state'"
        )
        machine.succeed(
            "${lib.getExe pkgs.jq} -e 'type == \"object\"' "
            "/var/lib/crowdsec/state/hub/.index.json"
        )
        machine.succeed("cscli lapi status")

    with subtest("registration keeps shared state public"):
        machine.succeed("test -d /var/lib/crowdsec")
        machine.fail("test -L /var/lib/crowdsec")
        machine.fail("test -e /var/lib/private/crowdsec")
        assert machine.succeed(
            "systemctl show crowdsec-firewall-bouncer-register.service "
            "--property=DynamicUser --value"
        ).strip() == "no"
        properties = {
            "NoNewPrivileges": "yes",
            "PrivateTmp": "yes",
            "ProtectSystem": "strict",
            "RestrictSUIDSGID": "yes",
        }
        for property_name, expected in properties.items():
            actual = machine.succeed(
                "systemctl show crowdsec-firewall-bouncer-register.service "
                f"--property={property_name} --value"
            ).strip()
            assert actual == expected, f"{property_name}: expected {expected}, got {actual}"

    with subtest("recover state migrated by the old unit"):
        credentials_hash = machine.succeed(f"sha256sum {credentials}").split()[0]
        api_key_hash = machine.succeed(f"sha256sum {api_key}").split()[0]
        machine.succeed(
            "systemctl stop crowdsec-firewall-bouncer.service "
            "crowdsec-firewall-bouncer-register.service crowdsec.service"
        )
        machine.succeed(
            "systemd-run --quiet --wait --unit=crowdsec-state-migrator "
            "--property=DynamicUser=true --property=User=crowdsec "
            "--property=Group=crowdsec "
            "--property='StateDirectory=crowdsec crowdsec-firewall-bouncer-register' "
            "${lib.getExe' pkgs.coreutils "true"}"
        )
        machine.succeed("test -L /var/lib/crowdsec")
        machine.succeed("test -L /var/lib/crowdsec-firewall-bouncer-register")
        machine.fail("sudo -u crowdsec test -d /var/lib/crowdsec")

        # Starting the agent itself must recover shared state before ExecStartPre,
        # without relying on a manual restart after bouncer registration.
        machine.succeed("systemctl start crowdsec.service")
        machine.wait_for_unit("crowdsec.service")
        machine.wait_for_open_port(8080)
        machine.succeed("test -d /var/lib/crowdsec")
        machine.fail("test -L /var/lib/crowdsec")
        machine.fail("test -e /var/lib/private/crowdsec")
        assert machine.succeed(f"sha256sum {credentials}").split()[0] == credentials_hash
        machine.succeed("cscli lapi status")

        machine.succeed("systemctl start crowdsec-firewall-bouncer-register.service")
        machine.succeed("test -d /var/lib/crowdsec-firewall-bouncer-register")
        machine.fail("test -L /var/lib/crowdsec-firewall-bouncer-register")
        machine.fail("test -e /var/lib/private/crowdsec-firewall-bouncer-register")
        assert machine.succeed(f"sha256sum {api_key}").split()[0] == api_key_hash
  '';
}
