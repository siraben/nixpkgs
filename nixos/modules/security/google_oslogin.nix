{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.security.googleOsLogin;
  package = pkgs.google-guest-oslogin;

in

{

  options = {

    security.googleOsLogin.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable Google OS Login.

        The OS Login package enables the following components:
        AuthorizedKeysCommand to authorize users, query valid SSH keys, and
        grant sudo access according to Google Cloud IAM permissions.
        NSS module to provide user and group information.
        PAM module for the sshd service to support two-factor authentication.
      '';
    };

  };

  config = lib.mkIf cfg.enable {
    security.pam.services.sshd = {
      makeHomeDir = true;
      googleOsLoginAuthentication = true;
    };

    security.sudo.extraConfig = ''
      #includedir /run/google-sudoers.d
    '';
    security.sudo-rs.extraConfig = ''
      #includedir /run/google-sudoers.d
    '';

    systemd.tmpfiles.rules = [
      "d /run/google-sudoers.d 750 root root -"
      "d /var/google-users.d 750 root root -"
    ];

    systemd.packages = [ package ];
    systemd.timers.google-oslogin-cache.wantedBy = [ "timers.target" ];

    # enable the nss module, so user lookups etc. work
    system.nssModules = [ package ];
    system.nssDatabases.passwd = [
      "cache_oslogin"
      "oslogin"
    ];
    system.nssDatabases.group = [
      "cache_oslogin"
      "oslogin"
    ];

    # Ugly: sshd refuses to start if a store path is given because /nix/store is group-writable.
    # So indirect by a symlink.
    environment.etc."ssh/authorized_keys_command_google_oslogin" = {
      mode = "0755";
      text = ''
        #!/bin/sh
        exec ${package}/bin/google_authorized_keys "$@"
      '';
    };
    services.openssh.authorizedKeysCommand = "/etc/ssh/authorized_keys_command_google_oslogin %u";
    services.openssh.authorizedKeysCommandUser = "root";
  };

}
