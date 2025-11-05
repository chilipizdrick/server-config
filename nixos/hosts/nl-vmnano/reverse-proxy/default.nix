{config, ...}: let
  liquidityPort = 8090;
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
      "liquidity.${domain}" = {
        extraConfig = ''
          handle_path /static/* {
            root * /var/www/liquidity/static/
            file_server
          }

          reverse_proxy * 127.0.0.1:${toString liquidityPort}
        '';
      };
    };
  };
}
