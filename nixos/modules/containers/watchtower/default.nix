{...}: {
  virtualisation.oci-containers.containers."watchtower" = {
    image = "quay.io/containrrr/watchtower:stable";
    extraOptions = [
      "--label-enable"
    ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
    ];
  };
}
