{
  evalSystem,
  runCommand,
}:
let
  package = runCommand "matrix-appservice-discord" { passthru = { }; } ''
    mkdir -p "$out/bin"
    touch "$out/bin/matrix-appservice-discord"
  '';

  serviceConfig =
    (evalSystem {
      services.matrix-appservice-discord = {
        enable = true;
        inherit package;
      };

      system.stateVersion = "26.05";
    }).config.systemd.services.matrix-appservice-discord.serviceConfig;
in
assert !(package.passthru ? nodeAppDir);
assert builtins.deepSeq serviceConfig true;
runCommand "matrix-appservice-discord-module-eval" { } ''
  touch "$out"
''
