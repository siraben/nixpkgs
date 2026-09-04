{ pkgs, ... }:
let
  sessionProbe = pkgs.writeShellScriptBin "keyring-session-probe" ''
    set -eu

    name="$1"
    other="$2"

    keyctl id @s > "/tmp/session-$name"
    keyctl describe @s > "/tmp/session-description-$name"
    # Grant test-only inspection permissions on this retained keyring. Isolation
    # below is still checked through each process's normal @s tree.
    keyctl setperm @s 0x3f3f3f3f
    keyctl search @s user login-shared-key > "/tmp/shared-key-$name"
    keyctl add user "$name-private-key" "$name-private-payload" @s > "/tmp/private-key-$name"
    touch "/tmp/ready-$name"

    while ! test -e "/tmp/ready-$other"; do sleep 0.1; done
    if keyctl search @s user "$other-private-key"; then
      touch "/tmp/cross-session-key-visible-$name"
    fi
    if keyctl search @s user caller-private-key; then
      touch "/tmp/caller-key-visible-$name"
    fi
    # Keep an external reference so the test can distinguish explicit PAM
    # revocation from an unreferenced keyring merely being garbage-collected.
    keyctl link @s "$3"
    touch "/tmp/checked-$name"

    while ! test -e /tmp/close-sessions; do sleep 0.1; done
  '';
in
{
  name = "pam-keyinit";

  nodes.machine =
    { ... }:
    {
      imports = [ ../../modules/profiles/minimal.nix ];

      virtualisation = {
        cores = 2;
        graphics = false;
      };
      boot.initrd.systemd.enable = false;
      networking.useDHCP = false;

      users = {
        mutableUsers = false;
        users.alice = {
          isNormalUser = true;
          uid = 1000;
        };
      };

      environment.systemPackages = with pkgs; [
        keyutils
        sessionProbe
        util-linux
      ];
    };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    with subtest("only login entry points initialize a keyring"):
        machine.succeed(
            "grep -E '^session optional .*/pam_keyinit[.]so force revoke' /etc/pam.d/login"
        )
        machine.fail("grep -E '^[^#].*pam_keyinit[.]so' /etc/pam.d/su")
        machine.fail("grep -E '^[^#].*pam_keyinit[.]so' /etc/pam.d/systemd-user")

    shared_key = machine.succeed(
        "setpriv --reuid=1000 --regid=100 --clear-groups "
        "keyctl add user login-shared-key shared-payload @u"
    ).strip()

    # A system service for the same user keeps systemd's private keyring. The
    # PAM policy must not make the user's keys visible to unrelated services.
    with subtest("system services retain private keyrings"):
        machine.fail(
            "systemd-run --quiet --wait --collect --pipe --uid=alice "
            "keyctl search @s user login-shared-key"
        )

    caller_private_key = machine.succeed(
        "keyctl add user caller-private-key caller-payload @s"
    ).strip()
    holder = machine.succeed("keyctl newring login-test-holder @s").strip()
    # Grant test-only permissions so the logins can retain their session-ring
    # references and the driver can inspect them through this holder. Production
    # key permissions are not changed.
    machine.succeed(f"keyctl setperm {holder} 0x3f3f3f3f")

    def start_login(name, other):
        machine.succeed(
            f"(printf 'exec keyring-session-probe {name} {other} {holder}\\n' | "
            f"script --quiet --return --command 'login -f alice' /dev/null; "
            f"touch /tmp/closed-{name}) >/tmp/login-{name}.log 2>&1 &"
        )

    with subtest("concurrent logins get owned and isolated keyrings"):
        start_login("one", "two")
        start_login("two", "one")
        machine.wait_for_file("/tmp/checked-one")
        machine.wait_for_file("/tmp/checked-two")

        first_session = machine.succeed("cat /tmp/session-one").strip()
        second_session = machine.succeed("cat /tmp/session-two").strip()
        assert first_session != second_session, (
            f"concurrent logins shared session keyring {first_session}"
        )

        for name in ["one", "two"]:
            machine.succeed(
                f"grep -E ' 1000 +100 keyring: _ses$' /tmp/session-description-{name}"
            )
            machine.succeed(f"grep -Fx {shared_key} /tmp/shared-key-{name}")
            machine.fail(f"test -e /tmp/cross-session-key-visible-{name}")
            machine.fail(f"test -e /tmp/caller-key-visible-{name}")

    with subtest("closing each login revokes only its session keyring"):
        # The backdoor can inspect both rings through the test holder before
        # logout, proving that failed post-logout lookups mean revocation rather
        # than insufficient permissions.
        machine.succeed(f"keyctl describe {first_session}")
        machine.succeed(f"keyctl describe {second_session}")

        machine.succeed("touch /tmp/close-sessions")
        machine.wait_for_file("/tmp/closed-one")
        machine.wait_for_file("/tmp/closed-two")
        machine.fail(f"keyctl describe {first_session}")
        machine.fail(f"keyctl describe {second_session}")

        # Revoking login-local rings must not revoke the UID-wide user key or
        # an unrelated service's private session key.
        machine.succeed(
            "setpriv --reuid=1000 --regid=100 --clear-groups "
            f"keyctl describe {shared_key}"
        )
        machine.succeed(f"keyctl describe {caller_private_key}")
  '';
}
