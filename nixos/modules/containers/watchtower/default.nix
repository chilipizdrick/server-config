{...}: {
  virtualisation.oci-containers.containers."watchtower" = {
    autoStart = true;
    image = "containrrr/watchtower";
    extraOptions = [
      "--pull=always"
    ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
    ];
  };
}
