{ lib, pkgs, ... }:

{
  name = "openssh-password-match";

  meta.maintainers = [ lib.maintainers.aszlig ];

  nodes = {
    server =
      { ... }:
      {
        environment.systemPackages = [ pkgs.sshpass ];
        virtualisation.graphics = false;

        services.openssh = {
          enable = true;
          settings = {
            KbdInteractiveAuthentication = false;
            PasswordAuthentication = false;
          };
          extraConfig = ''
            Match User password-allowed
              PasswordAuthentication yes
          '';
        };

        security.pam.services.sshd.unixAuth = true;

        users.groups.password-users = { };
        users.users = {
          password-allowed = {
            isNormalUser = true;
            group = "password-users";
            initialPassword = "correct-password";
          };
          password-denied = {
            isNormalUser = true;
            group = "password-users";
            initialPassword = "correct-password";
          };
        };
      };
  };

  testScript = ''
    start_all()

    server.wait_for_unit("sshd.service")

    password_ssh_options = (
        "-o ConnectTimeout=10 "
        "-o KbdInteractiveAuthentication=no "
        "-o NumberOfPasswordPrompts=1 "
        "-o PreferredAuthentications=password "
        "-o PubkeyAuthentication=no "
        "-o StrictHostKeyChecking=no "
        "-o UserKnownHostsFile=/dev/null"
    )

    with subtest("generated SSH and PAM configuration"):
        server.succeed("grep -Fx 'PasswordAuthentication no' /etc/ssh/sshd_config")
        server.succeed(
            "grep -E '^auth +sufficient +.*/pam_unix\\.so .*# unix ' /etc/pam.d/sshd"
        )
        server.succeed(
            "sshd -T -C user=password-allowed,host=client,addr=192.0.2.1 "
            "-f /etc/ssh/sshd_config | grep -Fxi 'passwordauthentication yes'"
        )
        server.succeed(
            "sshd -T -C user=password-denied,host=client,addr=192.0.2.1 "
            "-f /etc/ssh/sshd_config | grep -Fxi 'passwordauthentication no'"
        )
        server.succeed(
            "sshd -T -C user=password-denied,host=client,addr=192.0.2.1 "
            "-f /etc/ssh/sshd_config | grep -Fxi 'kbdinteractiveauthentication no'"
        )

    with subtest("matched user accepts the correct password"):
        server.succeed(
            f"sshpass -p correct-password ssh {password_ssh_options} "
            "password-allowed@localhost true",
            timeout=30,
        )

    with subtest("matched user rejects an incorrect password"):
        server.fail(
            f"sshpass -p wrong-password ssh {password_ssh_options} "
            "password-allowed@localhost true",
            timeout=30,
        )

    with subtest("unmatched user rejects the correct password"):
        server.fail(
            f"sshpass -p correct-password ssh {password_ssh_options} "
            "password-denied@localhost true",
            timeout=30,
        )
  '';
}
