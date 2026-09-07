{ lib, ... }:
let
  port = 6000;
in
{
  name = "gokapi";

  meta.maintainers = with lib.maintainers; [ delliott ];

  nodes.machine = { config, ... }: {
    services.gokapi = {
      enable = true;
      mutableSettings = false;
      settings = {
        Authentication = {
          # Disable authentication so the E2E setup page can be tested directly.
          Method = 3;
          SaltAdmin = "012345678901234567890123456789";
          SaltFiles = "012345678901234567890123456789";
          Username = "admin";
        };
        Port = "127.0.0.1:${toString port}";
        ServerUrl = "http://127.0.0.1:${toString port}/";
        DataDir = "/var/lib/gokapi/data";
        DatabaseUrl = "sqlite:///var/lib/gokapi/data/gokapi.sqlite";
        ConfigVersion = 22;
        # End-to-end encryption.
        Encryption.Level = 5;
      };
    };

    systemd.services.gokapi.serviceConfig.ExecStartPre = lib.mkAfter [
      "${lib.getExe config.services.gokapi.package} --deployment-password test-password"
    ];
  };

  testScript = ''
    machine.wait_for_unit("gokapi.service")
    machine.wait_for_open_port(${toString port})
    machine.succeed("curl --fail http://localhost:${toString port}/e2eSetup | grep -F 'js/min/wasm_exec.min.js'")
    machine.succeed("curl --fail http://localhost:${toString port}/js/min/wasm_exec.min.js | grep -F 'globalThis.Go'")
  '';
}
