{
  evalSystem,
  runCommand,
}:

let
  baseConfig = {
    services.netbird.server = {
      enable = true;
      domain = "netbird.example.test";

      coturn = {
        enable = true;
        password = "test-only";
      };

      dashboard.settings.AUTH_AUTHORITY = "https://id.example.test";
      management.oidcConfigEndpoint = "https://id.example.test/.well-known/openid-configuration";
    };
  };

  evalConfig =
    module:
    (evalSystem {
      imports = [
        baseConfig
        module
      ];
    }).config;

  defaults = evalConfig {
    services.coturn = {
      listening-port = 3479;
      tls-listening-port = 5349;
    };
  };

  overridden = evalConfig {
    services.netbird.server.management = {
      turnDomain = "turn.example.test";
      turnPort = 49152;
    };
  };
in

assert defaults.services.netbird.server.management.turnDomain == "netbird.example.test";
assert defaults.services.netbird.server.management.turnPort == 3479;
assert
  builtins.head defaults.services.netbird.server.management.settings.TURNConfig.Turns == {
    Password = "test-only";
    Proto = "udp";
    URI = "turn:netbird.example.test:3479";
    Username = "netbird";
  };
assert overridden.services.netbird.server.management.turnDomain == "turn.example.test";
assert overridden.services.netbird.server.management.turnPort == 49152;
assert
  (builtins.head overridden.services.netbird.server.management.settings.TURNConfig.Turns).URI
  == "turn:turn.example.test:49152";

runCommand "netbird-server-test" { } ''
  touch $out
''
