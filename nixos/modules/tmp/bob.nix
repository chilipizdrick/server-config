{...}: {
  services.nginx.virtualHosts."bob.chilipizdrick.xyz" = {
    addSSL = true;
    enableACME = true;
    locations = {
      "/" = {
        proxyPass = "http://localhost:8000";
      };
      "/static/" = {
        alias = "/var/www/static/";
      };
    };
  };
}
