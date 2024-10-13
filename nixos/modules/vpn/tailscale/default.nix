{pkgs, ...}: {
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    openFirewall = true;
    port = 41641;
    interfaceName = "tailscale0";
    extraUpFlags = [
      "--advertise-exit-node"
    ];
  };

  environment.systemPackages = [pkgs.tailscale];

  networking.firewall = {
    trustedInterfaces = ["tailscale0"];
  };
}
