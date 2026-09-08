{
  beeper,
  testers,
}:
testers.runNixOSTest {
  name = "beeper-timezone";

  nodes.machine.time.timeZone = "Asia/Kuala_Lumpur";

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    with subtest("detect system timezone when TZ is unset"):
        timezone = machine.succeed(
            "env -u TZ ELECTRON_RUN_AS_NODE=1 APPIMAGE=beeper "
            "${beeper}/bin/.beeper-wrapped "
            "-p 'Intl.DateTimeFormat().resolvedOptions().timeZone'"
        )
        assert timezone == "Asia/Kuala_Lumpur\n", f"Beeper detected the wrong timezone: {timezone!r}"

    with subtest("preserve explicit TZ override"):
        timezone = machine.succeed(
            "TZ=Europe/Zurich ELECTRON_RUN_AS_NODE=1 APPIMAGE=beeper "
            "${beeper}/bin/.beeper-wrapped "
            "-p 'Intl.DateTimeFormat().resolvedOptions().timeZone'"
        )
        assert timezone == "Europe/Zurich\n", f"Beeper ignored the TZ override: {timezone!r}"
  '';
}
