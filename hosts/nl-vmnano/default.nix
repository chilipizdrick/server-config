{
  inputs,
  config,
  ...
}: {
  imports = [
    (inputs.nixpkgs + "/nixos/modules/installer/scan/not-detected.nix")
    (inputs.nixpkgs + "/nixos/modules/profiles/qemu-guest.nix")
    ./disk-config.nix
    ./reverse-proxy.nix
    ./schizoid
    ./vpn
  ];

  sops.secrets.openflux-env = {
    sopsFile = ../../secrets/openflux.env;
    format = "dotenv";
    path = "/etc/openflux/.env";
    restartUnits = ["openflux.service"];
  };

  sops.secrets.openflux-vyandex-cookies = {
    sopsFile = ../../secrets/openflux-vyandex-cookies.txt;
    format = "binary";
    path = "/etc/openflux/cookies.txt";
    restartUnits = ["openflux.service"];
  };

  services.openflux = {
    enable = true;
    mode = "l3";
    strategy = "speed-first";
    channelName = "nl-vmnano-node";

    environmentFile = config.sops.secrets.openflux-env.path;

    transports = {
      direct.enable = true;
      vyandex = {
        enable = false;
        cookiesFile = config.sops.secrets.openflux-vyandex-cookies.path;
      };
      mailru.enable = false;
      cupsonline.enable = true;
      boards.enable = true;
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  time.timeZone = "Europe/Amsterdam";
  networking.hostName = "nl-vmnano";

  system.stateVersion = "25.11";
}
