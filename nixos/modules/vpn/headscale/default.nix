{config, ...}: let
  baseDomain = "chilipizdrick.xyz";
in {
  services.headscale = {
    enable = true;
    settings = {
      address = "0.0.0.0";
      port = 6969;
      server_url = "https://headscale.${baseDomain}";
      dns.base_domain = baseDomain;
    };
  };

  environment.systemPackages = [config.services.headscale.package];
}
