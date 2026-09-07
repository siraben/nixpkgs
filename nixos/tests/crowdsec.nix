{
  lib,
  pkgs,
  ...
}:
let
  # CrowdSec updates its hub index over the network during setup. Keep this
  # regression test hermetic while exercising the real daemon and all other
  # cscli commands.
  cscli = pkgs.writeShellScriptBin "cscli" ''
    if [[ "$#" -eq 3 && "$1" == -c=* && "$2" == hub && "$3" == update ]]; then
      printf '{}\n' > /var/lib/crowdsec/state/hub/.index.json
      exit 0
    fi

    exec ${lib.getExe' pkgs.crowdsec "cscli"} "$@"
  '';

  crowdsec = pkgs.buildEnv {
    name = "crowdsec-test";
    paths = [
      (lib.hiPrio cscli)
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
    };

    systemd.tmpfiles.rules = [ "f /var/log/crowdsec-test.log 0640 crowdsec crowdsec -" ];
  };

  testScript = ''
    credentials = "/var/lib/crowdsec/state/local_api_credentials.yaml"

    machine.wait_for_unit("crowdsec.service")
    machine.wait_for_open_port(8080)

    with subtest("writable state and generated credentials"):
        machine.wait_for_file(credentials)
        assert machine.succeed(
            f"stat -c '%a:%U:%G' {credentials}"
        ).strip() == "600:crowdsec:crowdsec"
        machine.succeed("sudo -u crowdsec test -w /var/lib/crowdsec/state")
        credentials_hash = machine.succeed(f"sha256sum {credentials}").split()[0]

    with subtest("local API is usable"):
        machine.succeed("cscli lapi status")

    with subtest("credentials survive a service restart"):
        machine.systemctl("restart crowdsec.service")
        machine.wait_for_unit("crowdsec.service")
        machine.wait_for_open_port(8080)
        assert machine.succeed(f"sha256sum {credentials}").split()[0] == credentials_hash
        machine.succeed("cscli lapi status")
  '';
}
