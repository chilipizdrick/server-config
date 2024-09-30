{...}: {
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [22 80 443];
      allowedTCPPortRanges = [
        {
          from = 1024;
          to = 65535;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1024;
          to = 65535;
        }
      ];
    };
  };
}
