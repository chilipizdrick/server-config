{config, ...}: let
  oksanaPort = 8080;
  headscaleUiPort = 2080;
  domain = "chilipizdrick.xyz";
in {
  services.caddy = {
    enable = true;
    email = "chilipizdrick@${domain}";
    virtualHosts = {
      "headscale.${domain}" = {
        extraConfig = ''
          reverse_proxy /web* 127.0.0.1:${toString headscaleUiPort}
          reverse_proxy * 127.0.0.1:${toString config.services.headscale.port}
        '';
      };
      "oksana.${domain}" = {
        extraConfig = ''
          reverse_proxy * 127.0.0.1:${toString oksanaPort}
        '';
      };
    };
  };
}
