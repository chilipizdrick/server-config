{config, ...}: let
  baseDomain = "chilipizdrick.xyz";
in {
  services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = 6969;
    settings = {
      server_url = "https://headscale.${baseDomain}:443";
      dns.base_domain = baseDomain;
    };
  };

  environment.systemPackages = [config.services.headscale.package];

  networking.firewall.allowedUDPPorts = [3478]; # DERP
}
