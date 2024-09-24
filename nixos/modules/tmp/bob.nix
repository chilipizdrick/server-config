{...}: {
  services.nginx.virtualHosts."bob.chilipizdrick.xyz" = {
    addSSL = true;
    enableACME = true;
    locations."/".proxyPass = "https://localhost:8000";
  };
}
