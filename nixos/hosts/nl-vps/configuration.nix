{...}: {
  imports = [
    ../base-configuration.nix
  ];

  time.timeZone = "Europe/Amsterdam";
  networking.hostName = "nl-vps";

  system.stateVersion = "23.11";
}
