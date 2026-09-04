{ ... }:

{
  name = "switch-to-configuration-recovery";

  nodes.machine = {
    boot.loader.grub.enable = false;

    # Connect from stage 1 so a heavily loaded builder cannot exhaust the
    # driver's five-minute connection deadline while stage 2 is starting.
    testing.initrdBackdoor = true;

    specialisation.changed.configuration.environment.etc."recovery-test".text = "changed";
  };

  testScript =
    { nodes, ... }:
    let
      changedSystem = nodes.machine.specialisation.changed.configuration.system.build.toplevel;
    in
    ''
      machine.wait_for_unit("initrd.target")
      machine.switch_root()
      machine.wait_for_unit("multi-user.target")

      recovery_root = "/tmp/recovery-root"
      machine.succeed(
          f"mkdir -p {recovery_root}/{{etc,run,nix,dev,proc,sys}} && "
          f"touch {recovery_root}/etc/NIXOS && "
          f"mount --rbind /nix {recovery_root}/nix && "
          f"mount --rbind /dev {recovery_root}/dev && "
          f"mount --rbind /proc {recovery_root}/proc && "
          f"mount --rbind /sys {recovery_root}/sys && "
          f"ln -s ${changedSystem} {recovery_root}/run/current-system"
      )

      with subtest("switch from a recovery chroot"):
          output = machine.fail(
              f"chroot {recovery_root} ${changedSystem}/bin/switch-to-configuration switch 2>&1"
          )
          assert "systemd is not running; cannot activate the NixOS configuration" in output
          assert "use `nixos-rebuild boot` and reboot instead" in output
          assert "Failed to open dbus connection" not in output
          assert "Warning: do not know how to make this configuration bootable" not in output

      with subtest("boot from a recovery chroot"):
          machine.succeed(
              f"chroot {recovery_root} ${changedSystem}/bin/switch-to-configuration boot 2>&1"
          )

      with subtest("D-Bus failure on a running system"):
          output = machine.fail(
              "unshare --mount sh -c '"
              "mount --make-rprivate / && "
              "mount -t tmpfs tmpfs /run/dbus && "
              "exec ${changedSystem}/bin/switch-to-configuration switch' 2>&1"
          )
          assert "Failed to open dbus connection" in output
          assert "systemd is not running" not in output

      with subtest("normal switch"):
          machine.succeed("${changedSystem}/bin/switch-to-configuration switch 2>&1")
          machine.succeed("grep -Fx changed /etc/recovery-test")
    '';
}
