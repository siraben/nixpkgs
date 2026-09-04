{ pkgs, ... }:
{
  name = "bcachefs";
  meta = {
    inherit (pkgs.bcachefs-tools.meta) maintainers;
  };

  nodes.machine =
    { pkgs, ... }:
    {
      virtualisation.emptyDiskImages = [ 4096 ];
      networking.hostId = "deadbeef";
      boot.supportedFilesystems = [ "bcachefs" ];
      environment.systemPackages = with pkgs; [
        parted
        keyutils
      ];
    };

  testScript = ''
    machine.succeed("modprobe bcachefs")
    machine.succeed("bcachefs version")
    machine.succeed("ls /dev")

    machine.succeed(
        "mkdir /tmp/mnt",
        "udevadm settle",
        "parted --script /dev/vdb mklabel msdos",
        "parted --script /dev/vdb -- mkpart primary 1024M 50% mkpart primary 50% -1s",
        "udevadm settle",
        "echo password | bcachefs format --encrypted --metadata_replicas 2 --label vtest /dev/vdb1 /dev/vdb2",
        # The installer console runs under the login PAM service. The default
        # bcachefs keyring is the user keyring, which must be linked into that
        # login's otherwise isolated session keyring for the mount syscall.
        "printf '%s\\n' 'set -e' 'keyctl show > /tmp/login-keyring' 'echo password | bcachefs unlock /dev/vdb1' 'mount -t bcachefs /dev/vdb1:/dev/vdb2 /tmp/mnt' 'bcachefs fs usage /tmp/mnt > /tmp/bcachefs-usage' 'exit' | script --quiet --return --command 'login -f root' /dev/null",
        "grep -q '_uid.0' /tmp/login-keyring",
        "test -s /tmp/bcachefs-usage",
        "udevadm settle",
        "umount /tmp/mnt",
        "udevadm settle",
    )
  '';
}
