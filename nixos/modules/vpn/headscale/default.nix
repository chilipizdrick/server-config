{config, ...}: let
  baseDomain = "chilipizdrick.xyz";
in {
  services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = 1080;
    settings = {
      server_url = "https://headscale.${baseDomain}:443";
      dns = {
        magic_dns = true;
        base_domain = baseDomain;
      };
      # oidc = {
      #   only_start_if_oidc_is_available = false;
      #   issuer = "https://accounts.google.com";
      #   client_id = "254958129928-h5k23p5mjg73902p5vi2jnpb6g2m2oq3.apps.googleusercontent.com";
      #   client_secret_path = config.sops.secrets."headscale/google_oidc_client_secret".path;
      #   scope = ["openid" "profile" "email"];
      # };
    };
  };

  environment.systemPackages = [config.services.headscale.package];

  networking.firewall.allowedUDPPorts = [3478]; # DERP
}
