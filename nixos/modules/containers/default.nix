{pkgs, ...}: {
  imports = [./headscale-ui];

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
    oci-containers.backend = "podman";
  };

  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}
