{config, ...}: let
  domain = "chilipizdrick.mooo.com";
in {
  services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = 1080;
    settings = {
      server_url = "https://headscale.${domain}:443";
      dns = {
        magic_dns = true;
        base_domain = domain;
        nameservers.global = [
          "1.1.1.1"
          "1.0.0.1"
          "2606:4700:4700::1111"
          "2606:4700:4700::1001"
        ];
      };
    };
  };

  environment.systemPackages = [config.services.headscale.package];

  networking.firewall.allowedUDPPorts = [3478]; # DERP
}
