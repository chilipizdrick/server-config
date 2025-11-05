{pkgs, ...}: {
  virtualisation = {
    docker = {
      enable = true;
    };
    oci-containers.backend = "docker";
  };

  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
