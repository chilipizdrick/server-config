{...}: {
  services.nginx.virtualHosts."bob.chilipizdrick.xyz" = {
    addSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://127.0.0.1:8000";
  };
}
