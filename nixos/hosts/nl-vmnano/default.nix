{inputs, ...}: {
  imports = [
    (inputs.nixpkgs + "/nixos/modules/installer/scan/not-detected.nix")
    (inputs.nixpkgs + "/nixos/modules/profiles/qemu-guest.nix")
    ./disk-config.nix
    ./reverse-proxy.nix
    ./schizoid
    ./vpn
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;

  time.timeZone = "Europe/Amsterdam";
  networking.hostName = "nl-vmnano";

  system.stateVersion = "25.11";
}
