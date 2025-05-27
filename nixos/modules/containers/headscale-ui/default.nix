{...}: {
  virtualisation.oci-containers.containers.headscale-ui = {
    image = "ghcr.io/gurucomputing/headscale-ui:latest";
    ports = ["2080:8080" "2443:8443"];
  };
}
