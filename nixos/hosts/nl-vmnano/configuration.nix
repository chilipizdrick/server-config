{inputs, ...}: {
  imports = [
    (inputs.nixpkgs + "/nixos/modules/installer/scan/not-detected.nix")
    (inputs.nixpkgs + "/nixos/modules/profiles/qemu-guest.nix")
    ../base-configuration.nix
    ./disk-config.nix
  ];

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;

  time.timeZone = "Europe/Amsterdam";
  networking.hostName = "nl-vmnano";

  system.stateVersion = "25.11";
}
