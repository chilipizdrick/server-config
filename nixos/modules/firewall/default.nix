{...}: {
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [22 80 443 2633 8000]; # 2633 is shadowbox port
    };
  };
}
