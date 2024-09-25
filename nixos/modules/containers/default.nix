{pkgs, ...}: {
  imports = [
    ./schizophrenia-bot
    ./watchtower
  ];

  virtualisation = {
    # podman.enable = true;
    docker.enable = true;
    oci-containers.backend = "docker";
  };

  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
