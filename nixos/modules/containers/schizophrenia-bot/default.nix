{inputs, ...}: {
  virtualisation.oci-containers.containers."schizophrenia-bot" = {
    image = "chilipizdrick/schizophrenia-bot";
    volumes = [
      "schizophrenia-bot-userdata:/app/userdata/:rw"
      "/etc/schizophrenia-bot/assets/:/app/assets/:ro"
    ];
    environmentFiles = [
      /etc/schizophrenia-bot/.env
    ];
    extraOptions = [
      "--pull=always"
    ];
  };

  environment.etc."schizophrenia-bot/assets".source = inputs.schizophrenia-bot-assets;
}
