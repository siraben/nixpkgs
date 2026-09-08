{ pkgs, ... }:
let
  inherit (pkgs) lib;

  evalConfig = import ../lib/eval-config.nix;

  postBootCommands =
    system:
    (evalConfig {
      system = null;
      modules = [
        {
          boot.crashDump.enable = true;
          nixpkgs.hostPlatform = system;
        }
      ];
    }).config.boot.postBootCommands;

  vgaOptions = [
    "--reset-vga"
    "--console-vga"
  ];
  hasAllVgaOptions =
    system:
    let
      commands = postBootCommands system;
    in
    lib.all (option: lib.hasInfix option commands) vgaOptions;
  hasNoVgaOptions =
    system:
    let
      commands = postBootCommands system;
    in
    lib.all (option: !lib.hasInfix option commands) vgaOptions;
in
assert hasAllVgaOptions "x86_64-linux";
assert hasAllVgaOptions "i686-linux";
assert hasNoVgaOptions "aarch64-linux";
assert hasNoVgaOptions "armv7l-linux";
pkgs.runCommand "crashdump-architecture-options" { } ''
  touch $out
''
