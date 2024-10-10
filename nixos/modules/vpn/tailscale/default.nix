{pkgs, ...}: {
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    openFirewall = true;
    port = 41641;
    interfaceName = "tailscale0";
  };

  environment.systemPackages = [pkgs.tailscale];

  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";
    after = ["network-pre.target" "tailscale.service"];
    wants = ["network-pre.target" "tailscale.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "oneshot";
    script = with pkgs; ''
      sleep 2

      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      ${tailscale}/bin/tailscale up -authkey tskey-examplekeyhere
    '';
  };

  networking.firewall = {
    trustedInterfaces = ["tailscale0"];
  };
}
