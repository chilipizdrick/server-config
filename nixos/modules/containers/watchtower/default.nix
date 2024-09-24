{...}: {
  virtualisation.oci-containers.containers."watchtower" = {
    image = "containrrr/watchtower";
    extraOptions = [
      # "--label-enable"
      "--interval 7200"
    ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
    ];
  };
}
