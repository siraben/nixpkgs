{
  lib,
  useSimpledrmOverride,
  ...
}:
let
  passphrase = "supersecret";
in
{
  name = "systemd-initrd-luks-plymouth";
  enableOCR = true;

  nodes.machine =
    { pkgs, ... }:
    {
      virtualisation = {
        emptyDiskImages = [ 512 ];
        useBootLoader = true;
        # Booting off the encrypted disk requires an available init script.
        mountHostNixStore = true;
        useEFIBoot = true;
      };
      boot.loader.systemd-boot.enable = true;

      environment.systemPackages = [ pkgs.cryptsetup ];

      specialisation.boot-luks.configuration = {
        testing.initrdBackdoor = true;
        boot = {
          blacklistedKernelModules = [
            "bochs"
            "bochs_drm"
            "cirrus"
            "qxl"
            "virtio_gpu"
          ];
          initrd = {
            availableKernelModules = [ "bochs" ];
            systemd = {
              enable = true;
              emergencyAccess = true;
              extraBin = {
                awk = lib.getExe pkgs.gawk;
                grep = lib.getExe pkgs.gnugrep;
              };
            };
            luks.devices = lib.mkVMOverride {
              cryptroot.device = "/dev/vdb";
            };
          };
          kernelParams = [
            "plymouth.debug=stream:/run/plymouth-debug.log"
            "plymouth.debug-key-events"
            # The test driver uses a serial console, but the graphical prompt
            # must be rendered on QEMU's display.
            "plymouth.ignore-serial-consoles"
          ];
          plymouth = {
            enable = true;
          }
          // lib.optionalAttrs (useSimpledrmOverride != null) {
            useSimpledrm = useSimpledrmOverride;
          };
        };
        virtualisation.rootDevice = "/dev/mapper/cryptroot";
      };
    };

  testScript =
    { nodes, ... }:
    let
      boot-luks = nodes.machine.specialisation.boot-luks.configuration.system.build.toplevel;
    in
    # python
    ''
      machine.wait_for_unit("multi-user.target")

      machine.succeed("echo -n ${passphrase} | cryptsetup luksFormat -q --iter-time=1 /dev/vdb -")
      machine.succeed("echo -n ${passphrase} | cryptsetup luksOpen -q /dev/vdb cryptroot")
      machine.succeed("mkfs.ext4 /dev/mapper/cryptroot")

      machine.succeed("${boot-luks}/bin/switch-to-configuration boot")
      machine.succeed("sync")
      machine.crash()

      machine.start()
      machine.wait_for_unit("systemd-ask-password-plymouth.service")
      machine.wait_until_succeeds("grep -Fq 'UseSimpledrm=${
        if useSimpledrmOverride != false then "1" else "0"
      }' /etc/plymouth/plymouthd.conf")
      machine.succeed("grep -Fq 'simple-framebuffer.0/drm/card0' /run/plymouth-debug.log || { grep -E 'ply-device-manager.*(found device|renderer|Timeout)' /run/plymouth-debug.log >&2; false; }")
      machine.wait_until_succeeds("grep -Fq 'adding pixel display' /run/plymouth-debug.log")
      machine.wait_until_succeeds("grep -Fq 'queuing password request with boot splash' /run/plymouth-debug.log")
      ${
        if useSimpledrmOverride != false then
          ''
            # The first graphical renderer must be available before Plymouth's
            # device timeout; otherwise the early prompt is delayed or textual.
            machine.succeed("awk '!display && /adding pixel display/{ display=NR } !timeout && /Timeout elapsed/{ timeout=NR } END { exit !(display && (!timeout || display < timeout)) }' /run/plymouth-debug.log")
          ''
        else
          ''
            # Reproduce the old default: Plymouth ignores simpledrm until its
            # eight-second device timeout has elapsed.
            machine.succeed("awk '!display && /adding pixel display/{ display=NR } !timeout && /Timeout elapsed/{ timeout=NR } END { exit !(display && timeout && timeout < display) }' /run/plymouth-debug.log")
          ''
      }
      machine.wait_for_text("Please enter passphrase")
      machine.screenshot("password-prompt")

      # Escape must reveal the detailed boot log and remain reversible.
      machine.send_key("esc")
      machine.wait_until_succeeds("grep -Fq 'escape key pressed' /run/plymouth-debug.log")
      machine.wait_for_text("Starting Cryptography Setup")
      machine.screenshot("boot-log")
      machine.send_key("esc")
      machine.wait_until_succeeds("awk '/escape key pressed/{ n++ } END { exit n < 2 }' /run/plymouth-debug.log")
      machine.wait_for_text("Please enter passphrase")

      # Exercise the simpledrm to hardware-specific DRM renderer handoff while
      # the prompt is active. QEMU's bochs DRM driver was blacklisted above so
      # that simpledrm would deterministically be selected first.
      machine.succeed("modprobe bochs")
      # QEMU keeps its simpledrm device registered when bochs takes over, so it
      # cannot exercise Plymouth's remove/add renderer path. It can still prove
      # that loading the hardware-specific driver leaves the prompt usable.
      machine.wait_for_text("Please enter passphrase", timeout=30)

      # An incorrect passphrase must be rejected and prompt again.
      machine.send_chars("incorrect")
      machine.send_key("ret")
      machine.wait_until_succeeds("awk '/queuing password request with boot splash/{ n++ } END { exit n < 2 }' /run/plymouth-debug.log")
      machine.fail("test -e /dev/mapper/cryptroot")
      machine.wait_for_text("Please enter passphrase")

      machine.send_chars("${passphrase}")
      machine.send_key("ret")
      machine.wait_until_succeeds("test -e /dev/mapper/cryptroot")
      machine.switch_root()
      machine.wait_for_unit("multi-user.target")
      machine.wait_for_unit("plymouth-quit.service")
      machine.fail("pgrep -x plymouthd")

      assert "/dev/mapper/cryptroot on / type ext4" in machine.succeed("mount")
    '';
}
