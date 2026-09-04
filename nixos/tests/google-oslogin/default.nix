{
  lib,
  pkgs,
  hostPkgs,
  ...
}:
let
  inherit (import ./../ssh-keys.nix hostPkgs)
    snakeOilPrivateKey
    snakeOilPublicKey
    ;

  # don't check host keys or known hosts, use the snakeoil ssh key
  ssh-config = builtins.toFile "ssh.conf" ''
    UserKnownHostsFile=/dev/null
    StrictHostKeyChecking=no
    IdentityFile=~/.ssh/id_snakeoil
  '';
in
{
  name = "google-oslogin";
  meta = {
    maintainers = [ ];
  };

  nodes.server = ./server.nix;
  testScript = ''
    LOCALUSER = "localuser"
    MOCKUSER = "mockuser_nixos_org"
    MOCKADMIN = "mockadmin_nixos_org"
    MOCKDENIED = "mockdenied_nixos_org"
    start_all()

    server.wait_for_unit("mock-google-metadata.service")
    server.wait_for_open_port(80)

    # The mock server should return a non-expired SSH key only for authorized users.
    server.succeed(
        f'${pkgs.google-guest-oslogin}/bin/google_authorized_keys {MOCKUSER} | grep -q "${snakeOilPublicKey}"'
    )
    server.succeed(
        f'${pkgs.google-guest-oslogin}/bin/google_authorized_keys {MOCKADMIN} | grep -q "${snakeOilPublicKey}"'
    )
    server.fail(
        f'${pkgs.google-guest-oslogin}/bin/google_authorized_keys {MOCKDENIED} | grep -q "${snakeOilPublicKey}"'
    )

    # Ensure the SSH login below, rather than the direct command above, grants admin access.
    server.succeed(f"rm -f /run/google-sudoers.d/{MOCKADMIN}")

    # Install the snakeoil SSH key and provision the SSH client configuration.
    server.succeed("mkdir -p ~/.ssh")
    server.succeed(
        "cat ${snakeOilPrivateKey} > ~/.ssh/id_snakeoil"
    )
    server.succeed("chmod 600 ~/.ssh/id_snakeoil")
    server.succeed("cp ${ssh-config} ~/.ssh/config")

    server.wait_for_unit("sshd.service")

    # The standard mixed local/OS Login SSH service must not use the strict
    # custom-stack account modules.
    server.fail("grep -E '^account .*pam_oslogin_(login|admin)\\.so' /etc/pam.d/sshd")

    # A local account with a valid key must remain usable when OS Login is enabled.
    server.succeed(f"ssh {LOCALUSER}@localhost 'true'")
    server.fail(f"test -e /run/google-sudoers.d/{LOCALUSER}")

    # Neither a nonexistent user nor an OS Login profile denied by IAM may connect.
    server.fail("ssh ghost@localhost 'true'")
    server.fail(f"ssh {MOCKDENIED}@localhost 'true'")

    # An authorized OS Login user can connect, but cannot sudo without adminLogin.
    server.succeed(f"ssh {MOCKUSER}@localhost 'true'")
    server.fail(
        f"ssh {MOCKUSER}@localhost '/run/wrappers/bin/sudo -n /run/current-system/sw/bin/id' | grep -q 'root'"
    )

    # An authorized administrator can connect and receives sudo access.
    server.succeed(
        f"ssh {MOCKADMIN}@localhost '/run/wrappers/bin/sudo -n /run/current-system/sw/bin/id' | grep -q 'root'"
    )
    server.succeed(f"test -e /run/google-sudoers.d/{MOCKADMIN}")
  '';
}
