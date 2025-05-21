{pkgs, ...}: {
  imports = [
    ./watchtower
  ];

  virtualisation = {
    # podman.enable = true;
    # oci-containers.backend = "podman";
    docker.enable = true;
    oci-containers.backend = "docker";
  };

  environment.systemPackages = with pkgs; [
    # podman-compose
    docker-compose
  ];
}
