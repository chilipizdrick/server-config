{...}: {
  imports = [
    ./schizophrenia-bot
    # ./binary-options-bot
  ];

  virtualisation = {
    # podman.enable = true;
    docker.enable = true;
    oci-containers.backend = "docker";
  };
}
