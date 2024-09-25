{inputs, ...}: {
  imports = [inputs.sops-nix.nixosModules.sops];

  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/etc/sops/age/keys.txt";
  };

  sops.secrets = {
    # "bob/docker_hub/password" = {
    #   path = "/etc/bob/docker_hub_password.txt";
    # };
    schizophrenia-bot-env = {
      sopsFile = ../../../secrets/schizophrenia-bot.env;
      format = "dotenv";
      path = "/etc/schizophrenia-bot/.env";
    };
    # bob-env = {
    #   sopsFile = ../../../secrets/bob.env;
    #   format = "dotenv";
    #   path = "/etc/bob/.env";
    # };
  };
}
