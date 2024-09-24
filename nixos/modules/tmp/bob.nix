{...}: {
  services.nginx.virtualHosts."bob.chilipizdrick.xyz" = {
    addSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://localhost:8000";
      extraConfig = ''
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_redirect off;
      '';
    };
  };
}
