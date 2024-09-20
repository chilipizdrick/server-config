{...}: {
  virtualisation.oci-containers.containers."schizophrenia-bot" = {
    image = "docker.io/chilipizdrick/schizophrenia-bot:latest";
    volumes = [
      "/etc/schizophrenia-bot/userdata:/app/userdata"
      "/etc/schizophrenia-bot/assets:/app/assets"
    ];
    environmentFiles = [
      /etc/schizophrenia-bot/.env
    ];
    extraOptions = [
      "--label 'com.centurylinklabs.watchtower.enable=true'"
    ];
  };
  system.activationScripts.create-schizophrenia-bot-volumes = ''
    mkdir -p /etc/schizophrenia-bot/userdata
    mkdir -p /etc/schizophrenia-bot/assets
  '';
}
