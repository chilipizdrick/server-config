{pkgs, ...}: {
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
    oci-containers.backend = "podman";
    # docker.enable = true;
    # oci-containers.backend = "docker";
  };

  environment.systemPackages = with pkgs; [
    podman-compose
    # docker-compose
  ];
}
