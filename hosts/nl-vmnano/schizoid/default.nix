{
  config,
  inputs,
  ...
}: let
  schizoidPkg = inputs.schizoid.packages."x86_64-linux".default;
in {
  environment.systemPackages = [schizoidPkg];

  sops.secrets.schizoid-env = {
    sopsFile = ../../../secrets/schizoid.env;
    format = "dotenv";
    path = "/etc/schizoid/.env";
    restartUnits = ["schizoid.service"];
  };

  environment.etc."schizoid/config.toml" = {
    source = ./config.toml;
    mode = "0644";
  };

  users.users.schizoid = {
    isSystemUser = true;
    group = "schizoid";
    home = "/var/lib/schizoid";
    createHome = false;
    description = "schizoid discord bot user";
  };
  users.groups.schizoid = {};

  systemd.services.schizoid = {
    description = "schizoid discord bot service";

    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target"];

    serviceConfig = {
      ExecStart = "${schizoidPkg}/bin/schizoid -c /etc/schizoid/config.toml";
      EnvironmentFile = config.sops.secrets."schizoid-env".path;

      Restart = "on-failure";
      RestartSec = "10s";

      User = "schizoid";
      Group = "schizoid";

      StateDirectory = "schizoid";
      WorkingDirectory = "/var/lib/schizoid";

      ProtectSystem = "strict";
      PrivateTmp = true;
    };
  };
}
