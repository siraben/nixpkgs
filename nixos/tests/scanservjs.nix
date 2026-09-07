let
  host = "127.0.0.2";
  port = 1234;
in
{
  name = "scanservjs";

  nodes.machine =
    { ... }:
    {
      services.scanservjs = {
        enable = true;
        settings.host = host;
        settings.port = port;
      };
    };

  testScript = ''
    machine.wait_for_unit("scanservjs.service")
    machine.wait_until_succeeds(
        "curl --ipv4 --noproxy '*' --silent --fail --show-error --location "
        "http://${host}:${toString port}"
    )
    machine.fail(
        "curl --ipv4 --noproxy '*' --silent --fail --show-error --max-time 2 "
        "http://127.0.0.1:${toString port}"
    )
  '';
}
