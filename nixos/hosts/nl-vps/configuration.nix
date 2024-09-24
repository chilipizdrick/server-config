{...}: {
  imports = [
    ./hardware-configuration.nix
    ../base-configuration.nix
    # ../../modules/tmp/bob.nix
    # ../../modules/containers/bob
  ];

  time.timeZone = "Europe/Amsterdam";
  networking.hostName = "nl-vps";

  system.stateVersion = "23.11";
}
