{...}: {
  virtualisation.oci-containers.containers."schizophrenia-bot" = {
    image = "chilipizdrick/schizophrenia-bot";
    volumes = [
      "/etc/schizophrenia-bot/userdata:/app/userdata"
      "/etc/schizophrenia-bot/assets:/app/assets"
    ];
    environmentFiles = [
      /etc/schizophrenia-bot/.env
    ];
    extraOptions = [
      "--pull=newer"
    ];
  };
  system.activationScripts.create-schizophrenia-bot-volumes = ''
    mkdir -p /etc/schizophrenia-bot/userdata
    mkdir -p /etc/schizophrenia-bot/assets
  '';
}
