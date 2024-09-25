{...}: {
  services.nginx = {
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    enable = true;
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "chilipizdrick@mail.chilipizdrick.xyz";
  };
}
