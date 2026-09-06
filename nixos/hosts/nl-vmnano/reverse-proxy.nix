{config, ...}: let
  domain = "chilipizdrick.mooo.com";
in {
  services.caddy = {
    enable = true;
    email = "chilipizdrick@${domain}";
    virtualHosts = {
      "headscale.${domain}" = {
        extraConfig = ''
          reverse_proxy * 127.0.0.1:${toString config.services.headscale.port}
        '';
      };
    };
  };
}
