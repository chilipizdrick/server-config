{inputs, ...}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/etc/sops/age/keys.txt";
    secrets = {
      "headscale/google_oidc_client_secret" = {};
      v2ray_config = {
        sopsFile = ../../../secrets/v2ray.json;
        format = "json";
        key = "";
        mode = "0444";
      };
    };
  };
}
