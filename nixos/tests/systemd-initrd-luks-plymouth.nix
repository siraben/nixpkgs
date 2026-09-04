{ lib, ... }:
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
          blacklistedKernelModules = [ "bochs" ];
          initrd = {
            availableKernelModules = [ "bochs" ];
            systemd = {
              enable = true;
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
            # The test driver uses a serial console, but the graphical prompt
            # must be rendered on QEMU's display.
            "plymouth.ignore-serial-consoles"
          ];
          plymouth.enable = true;
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
      machine.wait_until_succeeds("grep -Fq 'UseSimpledrm=1' /etc/plymouth/plymouthd.conf")
      machine.succeed("grep -Fq 'simple-framebuffer.0/drm/card0' /run/plymouth-debug.log || { grep -E 'ply-device-manager.*(found device|renderer|Timeout)' /run/plymouth-debug.log >&2; false; }")
      machine.wait_until_succeeds("grep -Fq 'adding pixel display' /run/plymouth-debug.log")
      # The graphical renderer must be available before Plymouth's timeout.
      machine.succeed("awk '!display && /adding pixel display/{ display=NR } !timeout && /Timeout elapsed/{ timeout=NR } END { exit !(display && (!timeout || display < timeout)) }' /run/plymouth-debug.log")
      machine.wait_for_text("Please enter passphrase")

      # The log view must remain available and reversible.
      machine.send_key("esc")
      machine.wait_for_text("Starting Cryptography Setup")
      machine.send_key("esc")
      machine.wait_for_text("Please enter passphrase")

      # QEMU retains simpledrm, so this verifies prompt usability after loading
      # a hardware-specific driver rather than renderer removal/replacement.
      machine.succeed("modprobe bochs")
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
