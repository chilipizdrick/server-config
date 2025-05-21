{config, ...}: let
  oksanaPort = 8000;
in {
  services.caddy = {
    enable = true;
    acmeCA = "https://acme-staging-v02.api.letsencrypt.org/directory";
    email = "chilipizdrick@chilipizdrick.xyz";
    virtualHosts = {
      "headscale.chilipizdrick.xyz" = {
        extraConfig = ''
          reverse_proxy * 127.0.0.1:${toString config.services.headscale.port}
        '';
      };
      "oksana.chilipizdrick.xyz" = {
        extraConfig = ''
          reverse_proxy * 127.0.0.1:${toString oksanaPort}
        '';
      };
    };
  };
}
