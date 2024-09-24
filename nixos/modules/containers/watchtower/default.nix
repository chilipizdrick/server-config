{...}: {
  virtualisation.oci-containers.containers."watchtower" = {
    image = "quay.io/containrrr/watchtower:stable";
    extraOptions = [
      "--label-enable"
      "--interval 7200"
    ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
    ];
  };
}
