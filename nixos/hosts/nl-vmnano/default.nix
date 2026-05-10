{inputs, ...}: {
  imports = [
    (inputs.nixpkgs + "/nixos/modules/installer/scan/not-detected.nix")
    (inputs.nixpkgs + "/nixos/modules/profiles/qemu-guest.nix")
    ../base-configuration.nix
    ./disk-config
    ./headscale-ui
    ./reverse-proxy
    ./schizoid
    ./vpn
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;

  time.timeZone = "Europe/Amsterdam";
  networking.hostName = "nl-vmnano";

  system.stateVersion = "25.11";
}
