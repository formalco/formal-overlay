{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.formal;
in
{
  options.services.formal = {
    enable = lib.mkEnableOption "Formal";
    package = lib.mkPackageOption pkgs "formal" { };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    systemd.user.services.formal = {
      Unit = {
        Description = "The Formal Desktop app for Linux";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/formal";
        StandardOutput = "journal";
        StandardError = "journal";
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}