{...}: {
  services.nginx = {
    enable = true;
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "chilipizdrick@chilipizdrick.xyz";
  };
}
