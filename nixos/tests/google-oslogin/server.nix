{ pkgs, ... }:
let
  inherit (import ./../ssh-keys.nix pkgs)
    snakeOilPrivateKey
    snakeOilPublicKey
    ;
in
{
  networking.firewall.allowedTCPPorts = [ 80 ];

  systemd.services.mock-google-metadata = {
    description = "Mock Google metadata service";
    serviceConfig.Type = "simple";
    serviceConfig.ExecStart = "${pkgs.python3}/bin/python ${./server.py}";
    environment = {
      SNAKEOIL_PUBLIC_KEY = snakeOilPublicKey;
    };
    wantedBy = [ "multi-user.target" ];
    requires = [ "network-addresses-lo.service" ];
    after = [
      "network.target"
      "network-addresses-lo.service"
    ];
  };

  services.openssh.enable = true;
  services.openssh.settings.KbdInteractiveAuthentication = false;
  services.openssh.settings.PasswordAuthentication = false;

  security.googleOsLogin.enable = true;

  users.users.localuser = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [ snakeOilPublicKey ];
  };

  # Mock google service
  networking.interfaces.lo.ipv4.addresses = [
    {
      address = "169.254.169.254";
      prefixLength = 32;
    }
  ];
}
