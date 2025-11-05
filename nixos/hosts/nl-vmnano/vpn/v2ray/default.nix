{config, ...}: {
  services.v2ray = {
    enable = true;
    configFile = config.sops.secrets.v2ray_config.path;
  };

  networking.firewall.allowedTCPPorts = [16823];
}
