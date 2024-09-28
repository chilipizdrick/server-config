{inputs, ...}: {
  imports = [inputs.sops-nix.nixosModules.sops];

  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/etc/sops/age/keys.txt";
  };

  sops.secrets = {
    schizophrenia-bot-env = {
      sopsFile = ../../../secrets/schizophrenia-bot.env;
      format = "dotenv";
      path = "/etc/schizophrenia-bot/.env";
    };
  };
}
