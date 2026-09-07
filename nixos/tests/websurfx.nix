{ lib, ... }:
{
  name = "websurfx";
  meta.maintainers = with lib.maintainers; [ SchweGELBin ];

  nodes.machine =
    { config, ... }:
    {
      services.websurfx = {
        enable = true;
        settings.port = 5090;
      };

      assertions = [
        {
          assertion =
            config.services.websurfx.settings ? http_cache_expiry_time
            && config.services.websurfx.settings.http_cache_expiry_time == 60;
          message = "websurfx must set the required HTTP cache expiry time";
        }
        {
          assertion =
            config.services.websurfx.settings.upstream_search_engines ? Qwant
            && !config.services.websurfx.settings.upstream_search_engines.Qwant;
          message = "websurfx must configure Qwant by default";
        }
        {
          assertion =
            config.services.websurfx.settings.upstream_search_engines ? SepiaSearch
            && !config.services.websurfx.settings.upstream_search_engines.SepiaSearch;
          message = "websurfx must configure SepiaSearch by default";
        }
      ];
    };

  testScript = ''
    machine.start()
    machine.wait_for_unit("websurfx.service")
    machine.wait_for_open_port(5090)
    machine.wait_until_succeeds("curl --fail --silent http://127.0.0.1:5090/ >/dev/null")
  '';
}
