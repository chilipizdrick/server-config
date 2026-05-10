{
  config,
  inputs',
  ...
}: {
  environment.systemPackages = [
    inputs'.schizoid.packages.default
  ];

  sops.secrets.schizoid-bot-env = {
    sopsFile = ../../../../secrets/schizoid-bot.env;
    format = "dotenv";
    path = "/etc/schizoid-bot/.env";
    restartUnits = ["schizoid.service"];
  };

  systemd.services.discord-bot = {
    description = "schizoid bot service";

    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target"];

    serviceConfig = {
      ExecStart = "${inputs'.schizoid.packages.schizoid}/bin/schizoid";
      EnvironmentFile = config.sops.secrets."schizoid-bot-env".path;
      Restart = "always";
      RestartSec = "10s";

      DynamicUser = true;
    };
  };
}
