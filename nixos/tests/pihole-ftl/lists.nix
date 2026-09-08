{
  lib,
  pkgs,
  ...
}:

let
  listServerPort = 8080;
  apiPort = 8081;
  blockListUrl = "http://127.0.0.1:${toString listServerPort}/block.txt";
  allowListUrl = "http://127.0.0.1:${toString listServerPort}/allow.txt";
  testLists = pkgs.runCommand "pihole-test-lists" { } ''
    mkdir -p "$out"
    echo blocked.example > "$out/block.txt"
    echo allowed.example > "$out/allow.txt"
    touch "$out/macvendor.db"
  '';
in
{
  name = "pihole-ftl-lists";
  meta.maintainers = with lib.maintainers; [ averyvigolo ];

  nodes.machine = {
    # gravity.sh requires these names to resolve before updating lists. Keep
    # the test independent of external DNS.
    networking.hosts."127.0.0.1" = [
      "github.com"
      "raw.githubusercontent.com"
    ];

    services.pihole-ftl = {
      enable = true;
      settings.webserver.port = toString apiPort;
      macvendorURL = "http://127.0.0.1:${toString listServerPort}/macvendor.db";
      lists = [
        {
          url = blockListUrl;
          type = "block";
          description = "test block list";
        }
        {
          url = allowListUrl;
          type = "allow";
          description = "test allow list";
        }
      ];
    };

    systemd.services = {
      pihole-test-lists = {
        description = "Serve Pi-hole test lists";
        wantedBy = [ "multi-user.target" ];
        before = [ "pihole-ftl-setup.service" ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.python3} -m http.server ${toString listServerPort} --bind 127.0.0.1 --directory ${testLists}";
          Restart = "on-failure";
        };
      };

      pihole-ftl-setup = {
        after = [ "pihole-test-lists.service" ];
        requires = [ "pihole-test-lists.service" ];
      };
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("pihole-test-lists.service")
    machine.wait_for_open_port(${toString listServerPort})
    machine.wait_for_unit("pihole-ftl.service")
    machine.wait_for_open_port(${toString apiPort})

    # Wait for the oneshot to finish and fail if list setup fails.
    machine.succeed("systemctl start pihole-ftl-setup.service")

    with subtest("configured allow and block lists are added through the API"):
        rows = machine.succeed(
            "${lib.getExe pkgs.pihole-ftl} sqlite3 /var/lib/pihole/gravity.db "
            "\"SELECT type, address, enabled, comment FROM adlist ORDER BY type;\""
        )
        assert rows.splitlines() == [
            "0|${blockListUrl}|1|test block list",
            "1|${allowListUrl}|1|test allow list",
        ], rows
  '';
}
