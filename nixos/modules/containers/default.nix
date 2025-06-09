{pkgs, ...}: {
  imports = [./headscale-ui];

  virtualisation = {
    docker = {
      enable = true;
    };
    # podman = {
    #   enable = true;
    #   dockerCompat = true;
    # };
    # oci-containers.backend = "podman";
    oci-containers.backend = "docker";
  };

  environment.systemPackages = with pkgs; [
    # podman-compose
    docker-compose
  ];
}
