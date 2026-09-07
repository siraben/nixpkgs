{ pkgs, ... }:
{
  name = "squeezelite-pulseaudio";
  meta.maintainers = with pkgs.lib.maintainers; [ adamcstephens ];

  nodes.machine = {
    boot.kernelModules = [ "snd-dummy" ];
    networking.useDHCP = false;

    services.pulseaudio = {
      enable = true;
      systemWide = true;
      daemon.config.realtime-scheduling = "no";
    };

    services.squeezelite = {
      enable = true;
      name = "test-player";
      pulseaudio.enable = true;
    };
  };

  testScript = ''
    machine.wait_for_unit("pulseaudio.service")
    machine.wait_for_unit("squeezelite.service")

    with subtest("squeezelite connects to the system-wide PulseAudio server"):
        machine.succeed("systemctl is-active squeezelite.service")
        machine.succeed("journalctl -u squeezelite.service -b | grep 'Dummy Output'")
        machine.fail("journalctl -u squeezelite.service -b | grep -E 'Failed to (create secure directory|load cookie file)|failed to connect to PulseAudio server'")
        machine.fail("journalctl -u pulseaudio.service -b | grep 'Denied access to client'")
  '';
}
