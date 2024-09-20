{...}: {
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [22 80 8080 2633];
    };
  };
}
